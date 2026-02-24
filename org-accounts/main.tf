#
# AWS Organization Member Accounts
#
# Base accounts (id, infra) are hardcoded.
# Additional accounts (projects, products) use for_each.
#

locals {
  email_format = "${var.org_email_alias}+%s@${var.org_email_domain}"
}

#
# Base Accounts (always present)
#

resource "aws_organizations_account" "id" {
  name      = "${var.org_name}-id"
  email     = format(local.email_format, "id")
  parent_id = var.main_ou_id

  iam_user_access_to_billing = "ALLOW"

  lifecycle {
    ignore_changes = [iam_user_access_to_billing]
  }

  tags = var.tags
}

resource "aws_organizations_account" "infra" {
  name      = "${var.org_name}-infra"
  email     = format(local.email_format, "infra")
  parent_id = var.main_ou_id

  iam_user_access_to_billing = "DENY"

  lifecycle {
    ignore_changes = [iam_user_access_to_billing]
  }

  tags = var.tags
}

#
# Additional Accounts (for_each)
#

resource "aws_organizations_account" "additional" {
  for_each = var.additional_accounts

  name      = each.key
  email     = format(local.email_format, each.key)
  parent_id = var.main_ou_id

  iam_user_access_to_billing = coalesce(each.value.iam_user_access_to_billing, "DENY")

  lifecycle {
    ignore_changes = [iam_user_access_to_billing]
  }

  tags = merge(var.tags, each.value.tags)
}
