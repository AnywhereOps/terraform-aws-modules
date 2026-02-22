# =============================================================================
# Required Variables
# =============================================================================

variable "name" {
  description = "Name prefix for resources (e.g., 'infra', 'packages')"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., 'prod', 'staging')"
  type        = string
}

# =============================================================================
# S3 Configuration
# =============================================================================

variable "bucket_name" {
  description = "Name for the S3 bucket. If not set, uses {name}-{environment}-packages"
  type        = string
  default     = ""
}

variable "force_destroy" {
  description = "Allow bucket deletion even if not empty (use with caution)"
  type        = bool
  default     = false
}

# =============================================================================
# CloudFront Configuration
# =============================================================================

variable "domain_name" {
  description = "Custom domain name for CloudFront (e.g., 'infra.anywhereops.ai')"
  type        = string
  default     = ""
}

variable "dns_zone_id" {
  description = "Route53 zone ID for custom domain DNS records"
  type        = string
  default     = ""
}

variable "origin_path" {
  description = "Path prefix in S3 bucket (e.g., 'repo/pkgs' for munki, '' for root)"
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
