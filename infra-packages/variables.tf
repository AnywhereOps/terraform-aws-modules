# -----------------------------------------------------------------------------
# Required
# -----------------------------------------------------------------------------

variable "bucket_name" {
  description = "Name of the S3 bucket for package storage."
  type        = string
}

variable "cloudfront_public_key_id" {
  description = "CloudFront public key ID created by bin/generate-signing-key.sh."
  type        = string
}

variable "signing_secret_arn" {
  description = "Secrets Manager ARN containing the signing private key, created by bin/generate-signing-key.sh."
  type        = string
}

# -----------------------------------------------------------------------------
# Naming / tagging
# -----------------------------------------------------------------------------

variable "name_prefix" {
  description = "Prefix for resource names (e.g. 'packages', 'cmh-packages')."
  type        = string
  default     = "packages"
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# CloudFront
# -----------------------------------------------------------------------------

variable "price_class" {
  description = "CloudFront price class. PriceClass_100 = US/EU only, PriceClass_All = global."
  type        = string
  default     = "PriceClass_100"
}

variable "domain_name" {
  description = "Custom domain name for the CloudFront distribution (e.g. packages.anywhereops.ai). Leave empty for default CF domain."
  type        = string
  default     = ""
}

variable "route53_zone_id" {
  description = "Route53 zone ID for ACM DNS validation and CNAME record. Required if domain_name is set."
  type        = string
  default     = ""
}
