#
# MFA Enforcement
#

variable "enforce_mfa" {
  description = "Whether to enforce MFA for specified users/groups"
  type        = bool
  default     = true
}

variable "mfa_enforced_groups" {
  description = "List of IAM group names to enforce MFA on"
  type        = list(string)
  default     = ["admins"]
}

variable "mfa_enforced_users" {
  description = "List of IAM user names to enforce MFA on"
  type        = list(string)
  default     = []
}

#
# Admin Users
#

variable "admin_users" {
  description = "List of admin user names to create"
  type        = list(string)
  default     = []
}

variable "force_destroy_users" {
  description = "Whether to force destroy users (delete even if they have keys/MFA)"
  type        = bool
  default     = true
}

#
# Admin Group
#

variable "admin_group_name" {
  description = "Name of the admin group"
  type        = string
  default     = "admins"
}

variable "admin_allowed_roles" {
  description = "List of role ARNs the admin group can assume"
  type        = list(string)
  default     = []
}

#
# Admin Role
#

variable "create_admin_role" {
  description = "Whether to create the admin role"
  type        = bool
  default     = true
}

#
# Billing Role
#

variable "create_billing_role" {
  description = "Whether to create the billing role"
  type        = bool
  default     = true
}

variable "billing_source_account_id" {
  description = "Account ID allowed to assume the billing role"
  type        = string
  default     = ""
}

#
# Common
#

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
