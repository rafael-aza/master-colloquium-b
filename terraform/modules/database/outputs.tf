output "rds_endpoint" {
  description = "RDS instance hostname (no port)"
  value       = aws_db_instance.this.address
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.this.port
}
