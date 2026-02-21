# =============================================================================
# S3 Bucket Outputs
# =============================================================================

output "bucket_id" {
  description = "Name of the S3 bucket."
  value       = module.packages.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket."
  value       = module.packages.arn
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket."
  value       = module.packages.bucket_regional_domain_name
}
