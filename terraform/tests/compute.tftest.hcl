# RED → GREEN: Compute module assertions
mock_provider "aws" {}

run "target_group_port_and_health_check" {
  module {
    source = "./modules/compute"
  }

  variables {
    name_prefix            = "tf"
    vpc_id                 = "vpc-12345678"
    public_subnet_ids      = ["subnet-pub-a", "subnet-pub-b"]
    private_app_subnet_ids = ["subnet-app-a", "subnet-app-b"]
    alb_sg_id              = "sg-alb-001"
    ec2_sg_id              = "sg-ec2-001"
    rds_endpoint           = "tf-rds.eu-central-1.rds.amazonaws.com"
    instance_type          = "t3.micro"
    min_size               = 1
    max_size               = 2
    desired_capacity       = 2
    db_user                = "admin"
    db_password            = "TestPassword123!"
    db_name                = "mysql"
  }

  command = plan

  assert {
    condition     = aws_lb_target_group.this.port == 4000
    error_message = "Target group port must be 4000"
  }

  assert {
    condition     = aws_lb_target_group.this.protocol == "HTTP"
    error_message = "Target group protocol must be HTTP"
  }

  assert {
    condition     = aws_lb_target_group.this.health_check[0].path == "/health"
    error_message = "Target group health check path must be /health"
  }
}

run "alb_internet_facing_on_port_80" {
  module {
    source = "./modules/compute"
  }

  variables {
    name_prefix            = "tf"
    vpc_id                 = "vpc-12345678"
    public_subnet_ids      = ["subnet-pub-a", "subnet-pub-b"]
    private_app_subnet_ids = ["subnet-app-a", "subnet-app-b"]
    alb_sg_id              = "sg-alb-001"
    ec2_sg_id              = "sg-ec2-001"
    rds_endpoint           = "tf-rds.eu-central-1.rds.amazonaws.com"
    instance_type          = "t3.micro"
    min_size               = 1
    max_size               = 2
    desired_capacity       = 2
    db_user                = "admin"
    db_password            = "TestPassword123!"
    db_name                = "mysql"
  }

  command = plan

  assert {
    condition     = aws_lb.this.internal == false
    error_message = "ALB must be internet-facing (internal = false)"
  }

  assert {
    condition     = aws_lb_listener.http.port == 80
    error_message = "ALB listener must be on port 80"
  }
}

run "asg_min_max_desired" {
  module {
    source = "./modules/compute"
  }

  variables {
    name_prefix            = "tf"
    vpc_id                 = "vpc-12345678"
    public_subnet_ids      = ["subnet-pub-a", "subnet-pub-b"]
    private_app_subnet_ids = ["subnet-app-a", "subnet-app-b"]
    alb_sg_id              = "sg-alb-001"
    ec2_sg_id              = "sg-ec2-001"
    rds_endpoint           = "tf-rds.eu-central-1.rds.amazonaws.com"
    instance_type          = "t3.micro"
    min_size               = 1
    max_size               = 2
    desired_capacity       = 2
    db_user                = "admin"
    db_password            = "TestPassword123!"
    db_name                = "mysql"
  }

  command = plan

  assert {
    condition     = aws_autoscaling_group.this.min_size == 1
    error_message = "ASG min_size must be 1"
  }

  assert {
    condition     = aws_autoscaling_group.this.max_size == 2
    error_message = "ASG max_size must be 2"
  }

  assert {
    condition     = aws_autoscaling_group.this.desired_capacity == 2
    error_message = "ASG desired_capacity must be 2"
  }
}

run "launch_template_uses_ec2_sg_and_user_data" {
  module {
    source = "./modules/compute"
  }

  variables {
    name_prefix            = "tf"
    vpc_id                 = "vpc-12345678"
    public_subnet_ids      = ["subnet-pub-a", "subnet-pub-b"]
    private_app_subnet_ids = ["subnet-app-a", "subnet-app-b"]
    alb_sg_id              = "sg-alb-001"
    ec2_sg_id              = "sg-ec2-001"
    rds_endpoint           = "tf-rds.eu-central-1.rds.amazonaws.com"
    instance_type          = "t3.micro"
    min_size               = 1
    max_size               = 2
    desired_capacity       = 2
    db_user                = "admin"
    db_password            = "TestPassword123!"
    db_name                = "mysql"
  }

  command = plan

  assert {
    condition     = contains(aws_launch_template.this.vpc_security_group_ids, var.ec2_sg_id)
    error_message = "Launch template must use the ec2_sg_id security group"
  }

  assert {
    condition     = aws_launch_template.this.instance_type == "t3.micro"
    error_message = "Launch template instance type must be t3.micro"
  }

  assert {
    condition     = aws_launch_template.this.user_data != null
    error_message = "Launch template must have user_data (bootstrap script)"
  }
}
