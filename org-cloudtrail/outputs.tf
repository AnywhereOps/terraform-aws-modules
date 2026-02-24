output "cloudtrail_arn" {
  description = "ARN of the CloudTrail"
  value       = module.cloudtrail.cloudtrail_arn
}

output "cloudtrail_id" {
  description = "ID of the CloudTrail"
  value       = module.cloudtrail.cloudtrail_id
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for CloudTrail encryption"
  value       = module.cloudtrail.kms_key_arn
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch Log Group"
  value       = module.cloudtrail.cloudwatch_log_group_arn
}
