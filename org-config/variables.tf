variable "config_name" {
  description = "Name of the AWS Config instance. Defaults to {account_alias}-config-{region}"
  type        = string
  default     = null
}

variable "config_logs_bucket" {
  description = "S3 bucket for AWS Config logs"
  type        = string
}

variable "aggregate_organization" {
  description = "Aggregate compliance data across the organization"
  type        = bool
  default     = true
}

variable "check_cloud_trail_encryption" {
  description = "Enable cloud-trail-encryption-enabled rule"
  type        = bool
  default     = true
}

variable "check_cloud_trail_log_file_validation" {
  description = "Enable cloud-trail-log-file-validation-enabled rule"
  type        = bool
  default     = true
}

variable "check_multi_region_cloud_trail" {
  description = "Enable multi-region-cloud-trail-enabled rule"
  type        = bool
  default     = true
}

variable "check_root_account_mfa_enabled" {
  description = "Enable root-account-mfa-enabled rule (only for org-root account)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
