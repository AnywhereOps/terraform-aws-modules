# =============================================================================
# S3 Bucket Outputs
# =============================================================================

output "bucket_id" {
  description = "ID/name of the S3 bucket"
  value       = aws_s3_bucket.packages.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.packages.arn
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket"
  value       = aws_s3_bucket.packages.bucket_regional_domain_name
}

# =============================================================================
# CloudFront Distribution Outputs
# =============================================================================

output "distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.main.id
}

output "distribution_arn" {
  description = "ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.main.arn
}

output "distribution_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "cloudfront_url" {
  description = "Full HTTPS URL (custom domain if set, otherwise CF default)"
  value       = local.cloudfront_url
}

# =============================================================================
# Signing Key Outputs
# =============================================================================

output "public_key_id" {
  description = "CloudFront public key ID (for signed URL generation)"
  value       = local.cloudfront_public_key_id
}

output "key_group_id" {
  description = "CloudFront key group ID"
  value       = aws_cloudfront_key_group.signing.id
}

output "signing_secret_arn" {
  description = "ARN of the Secrets Manager secret containing signing keys"
  value       = data.aws_secretsmanager_secret.signing.arn
}

output "signing_secret_name" {
  description = "Name of the Secrets Manager secret containing signing keys"
  value       = data.aws_secretsmanager_secret.signing.name
}

# =============================================================================
# IAM Outputs
# =============================================================================

output "signing_secret_policy_arn" {
  description = "ARN of the IAM policy granting access to the signing secret"
  value       = aws_iam_policy.signing_secret_access.arn
}

# =============================================================================
# Fleet/Munkisrv Integration Outputs
# =============================================================================

output "fleet_extra_secrets" {
  description = "Extra secrets map for Fleet's fleet_config.extra_secrets"
  value = {
    "FLEET_S3_SOFTWARE_INSTALLERS_CLOUDFRONT_URL"                       = "${data.aws_secretsmanager_secret.signing.arn}:cloudfront_url::"
    "FLEET_S3_SOFTWARE_INSTALLERS_CLOUDFRONT_URL_SIGNING_PRIVATE_KEY"   = "${data.aws_secretsmanager_secret.signing.arn}:private_key::"
    "FLEET_S3_SOFTWARE_INSTALLERS_CLOUDFRONT_URL_SIGNING_PUBLIC_KEY_ID" = "${data.aws_secretsmanager_secret.signing.arn}:cloudfront_public_key_id::"
  }
}

output "munkisrv_config" {
  description = "Configuration for munkisrv"
  value = {
    cloudfront_url     = local.cloudfront_url
    signing_secret_arn = data.aws_secretsmanager_secret.signing.arn
  }
}
