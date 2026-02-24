#
# AWS Organization Service Control Policies
#
# This module creates and attaches SCPs to organizational units.
# Uses the Trussworks module for common SCPs.
#

module "common_scps" {
  source  = "trussworks/org-scp/aws"
  version = "~> 1.6.0"

  # Deny root account usage
  deny_root_account_target_ids = var.deny_root_account_target_ids

  # Deny leaving the organization
  deny_leaving_orgs_target_ids = var.deny_leaving_orgs_target_ids

  # Require S3 encryption
  require_s3_encryption_target_ids = var.require_s3_encryption_target_ids

  # Deny all access (for suspended accounts)
  deny_all_access_target_ids = var.deny_all_access_target_ids

  # Optional: Region restrictions
  restrict_regions_target_ids = var.restrict_regions_target_ids
  allowed_regions             = var.allowed_regions
}

#
# Custom SCPs
#

resource "aws_organizations_policy" "custom" {
  for_each = var.custom_scps

  name        = each.key
  description = each.value.description
  type        = "SERVICE_CONTROL_POLICY"
  content     = each.value.content

  tags = merge(var.tags, each.value.tags)
}

resource "aws_organizations_policy_attachment" "custom" {
  for_each = { for item in local.custom_scp_attachments : "${item.policy_name}-${item.target_id}" => item }

  policy_id = aws_organizations_policy.custom[each.value.policy_name].id
  target_id = each.value.target_id
}

locals {
  custom_scp_attachments = flatten([
    for policy_name, policy in var.custom_scps : [
      for target_id in policy.target_ids : {
        policy_name = policy_name
        target_id   = target_id
      }
    ]
  ])
}
