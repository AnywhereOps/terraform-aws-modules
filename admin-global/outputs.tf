output "route53_zone" {
  description = "Zone details for the domain (only when core_infra = true)"
  value = var.core_infra ? {
    zone_id      = aws_route53_zone.zone[0].zone_id
    name_servers = aws_route53_zone.zone[0].name_servers
  } : null
}

output "logs_bucket" {
  description = "S3 bucket name for AWS logs (ALB, etc.)"
  value       = module.logs.aws_logs_bucket
}
