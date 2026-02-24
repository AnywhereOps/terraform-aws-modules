variable "trail_name" {
  description = "Name of the CloudTrail trail"
  type        = string
  default     = "cloudtrail"
}

variable "org_trail" {
  description = "Whether this is an organization trail"
  type        = bool
  default     = true
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for CloudTrail logs"
  type        = string
}

variable "s3_key_prefix" {
  description = "S3 key prefix for CloudTrail logs"
  type        = string
  default     = "cloudtrail"
}

variable "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch Log Group for CloudTrail"
  type        = string
  default     = "cloudtrail-events"
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 90
}

variable "encrypt_cloudtrail" {
  description = "Whether to encrypt CloudTrail with KMS"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
