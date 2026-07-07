output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "IDs of public subnets (for ALB)"
  value       = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

output "private_app_subnet_ids" {
  description = "IDs of private application subnets (for ASG)"
  value       = [aws_subnet.private_app_a.id, aws_subnet.private_app_b.id]
}

output "private_db_subnet_ids" {
  description = "IDs of private database subnets (for RDS subnet group)"
  value       = [aws_subnet.private_db_a.id, aws_subnet.private_db_b.id]
}
