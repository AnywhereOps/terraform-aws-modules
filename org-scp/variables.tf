#
# Common SCP targets (Trussworks module)
#

variable "deny_root_account_target_ids" {
  description = "List of OU/account IDs to attach deny-root-account SCP"
  type        = list(string)
  default     = []
}

variable "deny_leaving_orgs_target_ids" {
  description = "List of OU/account IDs to attach deny-leaving-orgs SCP"
  type        = list(string)
  default     = []
}

variable "require_s3_encryption_target_ids" {
  description = "List of OU/account IDs to attach require-s3-encryption SCP"
  type        = list(string)
  default     = []
}

variable "deny_all_access_target_ids" {
  description = "List of OU/account IDs to attach deny-all-access SCP (for suspended accounts)"
  type        = list(string)
  default     = []
}

variable "restrict_regions_target_ids" {
  description = "List of OU/account IDs to attach region restriction SCP"
  type        = list(string)
  default     = []
}

variable "allowed_regions" {
  description = "List of allowed AWS regions (when restrict_regions is enabled)"
  type        = list(string)
  default     = []
}

#
# Custom SCPs
#

variable "custom_scps" {
  description = "Map of custom SCPs to create and attach"
  type = map(object({
    description = string
    content     = string
    target_ids  = list(string)
    tags        = optional(map(string), {})
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to all SCPs"
  type        = map(string)
  default     = {}
}
