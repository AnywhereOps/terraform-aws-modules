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
  description = "Full HTTPS URL (custom domain if set, otherwise CF default)."
  value       = var.domain_name != "" ? "https://${var.domain_name}" : "https://${module.cdn.cloudfront_distribution_domain_name}"
}

output "cloudfront_key_group_id" {
  description = "CloudFront key group ID."
  value       = aws_cloudfront_key_group.signing.id
}

# -----------------------------------------------------------------------------
# Signing (managed by bin/generate-signing-key.sh)
# -----------------------------------------------------------------------------

output "signing_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the signing private key."
  value       = var.signing_secret_arn
}
