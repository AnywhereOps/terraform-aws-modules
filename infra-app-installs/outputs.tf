# -----------------------------------------------------------------------------
# S3
# -----------------------------------------------------------------------------

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

# -----------------------------------------------------------------------------
# CloudFront
# -----------------------------------------------------------------------------

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution."
  value       = module.cdn.cloudfront_distribution_id
}

output "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution."
  value       = module.cdn.cloudfront_distribution_arn
}

output "cloudfront_distribution_domain_name" {
  description = "Domain name of the CloudFront distribution."
  value       = module.cdn.cloudfront_distribution_domain_name
}

output "cloudfront_url" {
  description = "Full HTTPS URL of the CloudFront distribution. Use in munkisrv config.yaml."
  value       = "https://${module.cdn.cloudfront_distribution_domain_name}"
}

# -----------------------------------------------------------------------------
# Signing
# -----------------------------------------------------------------------------

output "cloudfront_key_id" {
  description = "CloudFront public key ID. Use in munkisrv config.yaml as key_id."
  value       = aws_cloudfront_public_key.signing.id
}

output "cloudfront_key_group_id" {
  description = "CloudFront key group ID."
  value       = aws_cloudfront_key_group.signing.id
}

# -----------------------------------------------------------------------------
# Secrets Manager
# -----------------------------------------------------------------------------

output "secret_arn" {
  description = "ARN of the Secrets Manager secret containing signing config."
  value       = var.create_secret ? aws_secretsmanager_secret.signing[0].arn : null
}

# -----------------------------------------------------------------------------
# Convenience: munkisrv config.yaml values
# -----------------------------------------------------------------------------

output "munkisrv_config" {
  description = "Map of values for munkisrv config.yaml cloudfront section."
  value = {
    url        = "https://${module.cdn.cloudfront_distribution_domain_name}"
    key_id     = aws_cloudfront_public_key.signing.id
    private_key = "RETRIEVE_FROM_SECRETS_MANAGER"
  }
}
