variable "name_prefix" {
  description = "Prefix applied to all resource names"
  type        = string
  default     = "tf"
}

variable "vpc_id" {
  description = "VPC ID in which to create the security groups"
  type        = string
}
