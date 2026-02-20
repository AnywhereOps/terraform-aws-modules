# -----------------------------------------------------------------------------
# Required
# -----------------------------------------------------------------------------

variable "bucket_name" {
  description = "Name of the S3 bucket for package storage."
  type        = string
}

variable "public_key" {
  description = "PEM-encoded public key for CloudFront signed URLs."
  type        = string
}

variable "private_key" {
  description = "PEM-encoded private key for CloudFront signed URLs. Stored in Secrets Manager."
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Naming / tagging
# -----------------------------------------------------------------------------

variable "name_prefix" {
  description = "Prefix for resource names (e.g. 'munkisrv', 'cmh-packages')."
  type        = string
  default     = "munkisrv"
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# S3 bucket
# -----------------------------------------------------------------------------

variable "use_account_alias_prefix" {
  description = "Whether to prefix the bucket name with the AWS account alias."
  type        = bool
  default     = false
}

variable "logging_bucket" {
  description = "S3 bucket for access logs. Empty string disables logging."
  type        = string
  default     = ""
}

variable "force_destroy" {
  description = "Allow destroying the bucket even when it contains objects."
  type        = bool
  default     = false
}

variable "versioning_status" {
  description = "Versioning status for the S3 bucket: Enabled, Disabled, or Suspended."
  type        = string
  default     = "Enabled"
}

# -----------------------------------------------------------------------------
# CloudFront
# -----------------------------------------------------------------------------

variable "price_class" {
  description = "CloudFront price class. PriceClass_100 = US/EU only, PriceClass_All = global."
  type        = string
  default     = "PriceClass_100"
}

variable "aliases" {
  description = "Custom domain names (CNAMEs) for the CloudFront distribution."
  type        = list(string)
  default     = []
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for custom domains. Required if aliases is non-empty."
  type        = string
  default     = null
}

variable "minimum_protocol_version" {
  description = "Minimum TLS version for viewers."
  type        = string
  default     = "TLSv1.2_2021"
}

variable "enable_logging" {
  description = "Enable CloudFront access logging to S3."
  type        = bool
  default     = false
}

variable "logging_config" {
  description = "CloudFront logging configuration. Only used when enable_logging is true."
  type = object({
    bucket = string
    prefix = optional(string, "cloudfront")
  })
  default = null
}

variable "geo_restriction_type" {
  description = "Type of geo restriction: none, whitelist, or blacklist."
  type        = string
  default     = "none"
}

variable "geo_restriction_locations" {
  description = "ISO 3166-1-alpha-2 country codes for geo restriction."
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Secrets Manager
# -----------------------------------------------------------------------------

variable "create_secret" {
  description = "Whether to store the signing keypair and CloudFront URL in Secrets Manager."
  type        = bool
  default     = true
}

variable "secret_name" {
  description = "Name for the Secrets Manager secret."
  type        = string
  default     = ""
}
