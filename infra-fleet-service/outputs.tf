# ALB outputs
output "alb_target_group_arn" {
  description = "ARN of the ALB target group"
  value       = module.alb_fleet.alb_target_group_id
}

output "alb_security_group_id" {
  description = "Security group ID of the ALB"
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
  description = "ARN suffix of the ALB (for CloudWatch metrics)"
  value       = module.alb_fleet.alb_arn_suffix
}

output "alb_listener_arn" {
  description = "ARN of the HTTPS listener"
  value       = module.alb_fleet.alb_listener_arn
}

# ECS outputs
output "task_definition_arn" {
  description = "ARN of the Fleet ECS task definition"
  value       = aws_ecs_task_definition.fleet.arn
}

output "task_definition_revision" {
  description = "Revision of the Fleet ECS task definition"
  value       = aws_ecs_task_definition.fleet.revision
}

output "service_name" {
  description = "Name of the Fleet ECS service"
  value       = aws_ecs_service.fleet.name
}

output "fleet_image_deployed" {
  description = "The Fleet image currently deployed"
  value       = local.fleet_effective_image
}

# IAM outputs
output "task_role_arn" {
  description = "ARN of the Fleet task role"
  value       = aws_iam_role.fleet_task.arn
}

output "execution_role_arn" {
  description = "ARN of the Fleet execution role"
  value       = aws_iam_role.fleet_execution.arn
}
