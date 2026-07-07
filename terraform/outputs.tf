output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer — use this to verify the deployment"
  value       = module.compute.alb_dns_name
}

output "rds_endpoint" {
  description = "RDS instance endpoint (host only, no port)"
  value       = module.database.rds_endpoint
  sensitive   = true
}
