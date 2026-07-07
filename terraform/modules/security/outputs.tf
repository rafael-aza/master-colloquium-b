output "alb_sg_id" {
  description = "Security group ID for the Application Load Balancer"
  value       = aws_security_group.alb.id
}

output "ec2_sg_id" {
  description = "Security group ID for EC2 application servers"
  value       = aws_security_group.ec2.id
}

output "rds_sg_id" {
  description = "Security group ID for the RDS database"
  value       = aws_security_group.rds.id
}
