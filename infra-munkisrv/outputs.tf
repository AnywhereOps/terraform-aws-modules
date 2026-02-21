output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = module.alb_munkisrv.alb_dns_name
}

output "alb_zone_id" {
  description = "Route53 zone ID of the ALB"
  value       = module.alb_munkisrv.alb_zone_id
}

output "service_name" {
  description = "Name of the ECS service"
  value       = module.ecs_service_munkisrv.service_name
}

output "task_role_arn" {
  description = "ARN of the ECS task role"
  value       = module.ecs_service_munkisrv.task_role_arn
}

output "task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = module.ecs_service_munkisrv.task_execution_role_arn
}

output "domain_name" {
  description = "Domain name for munkisrv"
  value       = var.domain_name
}

output "url" {
  description = "Full HTTPS URL for munkisrv"
  value       = "https://${var.domain_name}"
}
