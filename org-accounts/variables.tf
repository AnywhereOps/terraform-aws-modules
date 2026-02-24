variable "org_name" {
  description = "Organization name (e.g., anywhereops)"
  type        = string
}

variable "org_email_alias" {
  description = "Email alias for account emails (e.g., anywhereops-infra)"
  type        = string
}

variable "org_email_domain" {
  description = "Email domain for account emails (e.g., truss.works)"
  type        = string
}

variable "main_ou_id" {
  description = "ID of the main organizational unit for accounts"
  type        = string
}

variable "additional_accounts" {
  description = "Map of additional accounts to create (for_each)"
  type = map(object({
    iam_user_access_to_billing = optional(string)
    tags                       = optional(map(string), {})
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to all accounts"
  type        = map(string)
  default     = {}
}
