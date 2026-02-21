# =============================================================================
# Required Variables
# =============================================================================

variable "name" {
  description = "Name prefix for resources (e.g., 'packages', 'fleet-installers')"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., 'prod', 'staging')"
  type        = string
}

variable "s3_bucket_id" {
  description = "ID/name of the S3 bucket to serve via CloudFront"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  type        = string
}

variable "s3_bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket"
  type        = string
}

# =============================================================================
# Optional Variables
# =============================================================================

variable "origin_path" {
  description = "Path prefix in S3 bucket (e.g., 'repo/pkgs' for munki, '' for root)"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Custom domain name for CloudFront (optional)"
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for custom domain (required if domain_name is set)"
  type        = string
  default     = ""
}

variable "dns_zone_id" {
  description = "Route53 zone ID for custom domain (optional)"
  type        = string
  default     = ""
}

variable "price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100" # US, Canada, Europe
}

variable "default_ttl" {
  description = "Default TTL for cached objects (seconds)"
  type        = number
  default     = 86400 # 1 day
}

variable "max_ttl" {
  description = "Maximum TTL for cached objects (seconds)"
  type        = number
  default     = 31536000 # 1 year
}

variable "min_ttl" {
  description = "Minimum TTL for cached objects (seconds)"
  type        = number
  default     = 0
}

variable "logging_bucket" {
  description = "S3 bucket for CloudFront access logs (optional)"
  type        = string
  default     = ""
}

variable "logging_prefix" {
  description = "Prefix for CloudFront access logs"
  type        = string
  default     = "cloudfront/"
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
