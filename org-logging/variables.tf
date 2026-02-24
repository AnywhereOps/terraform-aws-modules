variable "bucket_name" {
  description = "Name of the S3 logs bucket"
  type        = string
}

variable "default_allow" {
  description = "Whether to allow all logging by default"
  type        = bool
  default     = false
}

variable "allow_cloudtrail" {
  description = "Whether to allow CloudTrail logging"
  type        = bool
  default     = true
}

variable "allow_config" {
  description = "Whether to allow AWS Config logging"
  type        = bool
  default     = true
}

variable "allow_alb" {
  description = "Whether to allow ALB access logging"
  type        = bool
  default     = false
}

variable "allow_nlb" {
  description = "Whether to allow NLB access logging"
  type        = bool
  default     = false
}

variable "cloudtrail_accounts" {
  description = "List of account IDs allowed to write CloudTrail logs. If null, uses all accounts in the organization."
  type        = list(string)
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
