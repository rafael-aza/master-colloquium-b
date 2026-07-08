# ─── AMI Data Source — Ubuntu 24.04 LTS (Canonical) ──────────────────────────
# NOTE: originally pinned to 22.04 (jammy), but the plain 22.04 SSD AMI listing
# was unavailable in the AWS console at the time of the manual deployment run
# (see note.md decision #7). Switched to 24.04 (noble) for BOTH environments
# to keep the manual vs Terraform comparison fair (same OS/AMI family).
# NOTE 2: 24.04-era Canonical AMIs are published under the "hvm-ssd-gp3" path,
# not "hvm-ssd" (that was the 22.04-era convention) — confirmed via
# `aws ec2 describe-images`. `terraform plan` caught this immediately
# ("Your query returned no results") before any resources were touched.
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ─── Application Load Balancer ────────────────────────────────────────────────
resource "aws_lb" "this" {
  name               = "${var.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  tags = { Name = "${var.name_prefix}-alb" }
}

# ─── Target Group — :4000 with /health check ──────────────────────────────────
resource "aws_lb_target_group" "this" {
  name     = "${var.name_prefix}-tg"
  port     = 4000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = { Name = "${var.name_prefix}-tg" }
}

# ─── ALB Listener — HTTP :80 → forward to target group ────────────────────────
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

# ─── Launch Template — Ubuntu 22.04, user-data injects DB config ──────────────
resource "aws_launch_template" "this" {
  name_prefix   = "${var.name_prefix}-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  vpc_security_group_ids = [var.ec2_sg_id]

  user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    rds_endpoint = var.rds_endpoint
    db_user      = var.db_user
    db_password  = var.db_password
    db_name      = var.db_name
    app_repo_url = var.app_repo_url
  }))

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.name_prefix}-ec2" }
  }
}

# ─── Auto Scaling Group — min 1 / max 2 / desired 2 ──────────────────────────
resource "aws_autoscaling_group" "this" {
  name                = "${var.name_prefix}-asg"
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity
  vpc_zone_identifier = var.private_app_subnet_ids
  target_group_arns   = [aws_lb_target_group.this.arn]
  health_check_type   = "ELB"

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-ec2"
    propagate_at_launch = true
  }
}
