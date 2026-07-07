variable "name_prefix" {
  description = "Prefix applied to all resource names"
  type        = string
  default     = "tf"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the ALB (must span at least 2 AZs)"
  type        = list(string)
}

variable "private_app_subnet_ids" {
  description = "Private subnet IDs for the ASG EC2 instances"
  type        = list(string)
}

variable "alb_sg_id" {
  description = "Security group ID for the ALB"
  type        = string
}

variable "ec2_sg_id" {
  description = "Security group ID for EC2 instances"
  type        = string
}

variable "rds_endpoint" {
  description = "RDS hostname injected as DB_HOST into the EC2 user-data"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "min_size" {
  description = "ASG minimum capacity"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "ASG maximum capacity"
  type        = number
  default     = 2
}

variable "desired_capacity" {
  description = "ASG desired capacity"
  type        = number
  default     = 2
}

variable "db_user" {
  description = "Database username injected as DB_USER into the EC2 user-data"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Database password injected as DB_PWD into the EC2 user-data"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Database name injected as DB_NAME into the EC2 user-data"
  type        = string
  default     = "mysql"
}

variable "app_repo_url" {
  description = "Public HTTPS URL of the app repository cloned by the EC2 user-data"
  type        = string
}
