variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-central-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_a" {
  description = "Primary availability zone"
  type        = string
  default     = "eu-central-1a"
}

variable "az_b" {
  description = "Secondary availability zone"
  type        = string
  default     = "eu-central-1b"
}

variable "name_prefix" {
  description = "Prefix applied to all resource names"
  type        = string
  default     = "tf"
}

variable "instance_type" {
  description = "EC2 instance type for application servers"
  type        = string
  default     = "t3.micro"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_engine_version" {
  description = "MySQL engine version"
  type        = string
  default     = "8.0"
}

variable "db_multi_az" {
  description = "Enable Multi-AZ for RDS"
  type        = bool
  default     = true
}

variable "db_username" {
  description = "Master username for RDS"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Master password for RDS — set via TF_VAR_db_password or prompted at apply time"
  type        = string
  sensitive   = true
}

variable "app_repo_url" {
  description = "Public HTTPS URL of the app repository the EC2 instances clone at boot"
  type        = string
  default     = "https://github.com/rafael-aza/master-colloquium-b.git"
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
