variable "name_prefix" {
  description = "Prefix applied to all resource names"
  type        = string
  default     = "tf"
}

variable "db_subnet_ids" {
  description = "Subnet IDs for the RDS DB subnet group (must span at least 2 AZs)"
  type        = list(string)
}

variable "rds_sg_id" {
  description = "Security group ID to attach to the RDS instance"
  type        = string
}

variable "db_username" {
  description = "Master username for the RDS instance"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Master password for the RDS instance"
  type        = string
  sensitive   = true
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
  description = "Enable Multi-AZ deployment for the RDS instance"
  type        = bool
  default     = true
}
