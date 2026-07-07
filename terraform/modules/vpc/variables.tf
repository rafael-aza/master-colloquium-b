variable "name_prefix" {
  description = "Prefix applied to all resource names"
  type        = string
  default     = "tf"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_a" {
  description = "Primary availability zone (hosts Public A, App A, DB A subnets)"
  type        = string
  default     = "eu-central-1a"
}

variable "az_b" {
  description = "Secondary availability zone (hosts Public B, App B, DB B subnets)"
  type        = string
  default     = "eu-central-1b"
}
