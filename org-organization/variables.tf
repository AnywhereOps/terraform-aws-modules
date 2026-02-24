variable "service_access_principals" {
  description = "List of AWS service principals to enable for the organization"
  type        = list(string)
  default = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "guardduty.amazonaws.com",
  ]
}

variable "enabled_policy_types" {
  description = "List of policy types to enable for the organization"
  type        = list(string)
  default     = ["SERVICE_CONTROL_POLICY"]
}

variable "feature_set" {
  description = "Feature set for the organization (ALL or CONSOLIDATED_BILLING)"
  type        = string
  default     = "ALL"
}

variable "organizational_units" {
  description = "Map of organizational units to create"
  type = map(object({
    parent_id = optional(string) # If null, uses org root
    tags      = optional(map(string), {})
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
