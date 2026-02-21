# ALB outputs - these are used by ECS services to register with the load balancer
output "alb_target_group_arn" {
  description = "ARN of the ALB target group (used by ECS service to register tasks)"
  value       = module.alb_fleet.alb_target_group_id
}

output "alb_security_group_id" {
  description = "Security group ID of the ALB (used by ECS service for ingress rules)"
  value       = module.alb_fleet.alb_security_group_id
}

output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = module.alb_fleet.alb_dns_name
}

output "alb_arn" {
  description = "ARN of the ALB"
  value       = module.alb_fleet.alb_arn
}

output "alb_arn_suffix" {
  description = "ARN suffix of the ALB (used for CloudWatch metrics)"
  value       = module.alb_fleet.alb_arn_suffix
}

output "alb_listener_arn" {
  description = "ARN of the HTTPS listener (used for adding listener rules)"
  value       = module.alb_fleet.alb_listener_arn
}

output "cross_account_kms_key_arn" {
  description = "ARN of the KMS key for cross-account secret access"
  value       = length(aws_kms_key.cross_account_secrets) > 0 ? aws_kms_key.cross_account_secrets[0].arn : null
}
