# ─── DB Subnet Group ──────────────────────────────────────────────────────────
resource "aws_db_subnet_group" "this" {
  name        = "${var.name_prefix}-db-subnet-group"
  description = "Private subnets spanning two AZs for RDS Multi-AZ"
  subnet_ids  = var.db_subnet_ids

  tags = { Name = "${var.name_prefix}-db-subnet-group" }
}

# ─── Parameter Group ──────────────────────────────────────────────────────────
resource "aws_db_parameter_group" "this" {
  name        = "${var.name_prefix}-mysql-pg"
  family      = "mysql8.0"
  description = "Parameter group for MySQL 8.0"

  tags = { Name = "${var.name_prefix}-mysql-pg" }
}

# ─── RDS Instance ─────────────────────────────────────────────────────────────
# No db_name set: connect to the 'mysql' system schema (SELECT NOW() requires no schema).
resource "aws_db_instance" "this" {
  identifier             = "${var.name_prefix}-rds"
  engine                 = "mysql"
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  allocated_storage      = 20
  storage_type           = "gp2"
  port                   = 3306
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.rds_sg_id]
  parameter_group_name   = aws_db_parameter_group.this.name
  multi_az               = var.db_multi_az
  publicly_accessible    = false
  skip_final_snapshot    = true

  tags = { Name = "${var.name_prefix}-rds" }
}
