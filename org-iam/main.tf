#
# AWS IAM for Organization Root Account
#
# This module creates IAM users, groups, roles, and policies
# for the organization management account.
#

data "aws_caller_identity" "current" {}

#
# MFA Enforcement
#

module "iam_enforce_mfa" {
  count = var.enforce_mfa ? 1 : 0

  source  = "trussworks/mfa/aws"
  version = "~> 4.1.0"

  iam_groups = var.mfa_enforced_groups
  iam_users  = var.mfa_enforced_users
}

#
# Admin Users
#

resource "aws_iam_user" "admins" {
  for_each = toset(var.admin_users)

  name          = each.value
  force_destroy = var.force_destroy_users

  tags = var.tags
}

#
# Admin Group
#

module "admins_group" {
  count = length(var.admin_users) > 0 ? 1 : 0

  source  = "trussworks/iam-user-group/aws"
  version = "3.0.0"

  user_list     = var.admin_users
  group_name    = var.admin_group_name
  allowed_roles = var.admin_allowed_roles

  depends_on = [aws_iam_user.admins]
}

#
# Admin Role (for role assumption)
#

data "aws_iam_policy_document" "role_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.account_id]
    }
    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }
  }
}

resource "aws_iam_role" "admin" {
  count = var.create_admin_role ? 1 : 0

  name               = "admin"
  description        = "Role for organization administrators"
  assume_role_policy = data.aws_iam_policy_document.role_assume_role_policy.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "admin_administrator_access" {
  count = var.create_admin_role ? 1 : 0

  role       = aws_iam_role.admin[0].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

#
# Billing Role (limited access for billing only)
#

data "aws_iam_policy_document" "limited_billing_access" {
  statement {
    sid    = "AllowAccessToBudgetsAndCostExplorer"
    effect = "Allow"
    actions = [
      "aws-portal:ViewBilling",
      "aws-portal:ViewUsage",
      "budgets:ViewBudget",
      "ce:View*",
      "pricing:*"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "DenyAccessToAccountAndPaymentMethod"
    effect = "Deny"
    actions = [
      "aws-portal:*Account",
      "aws-portal:*PaymentMethods",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "limited_billing_access" {
  count = var.create_billing_role ? 1 : 0

  name        = "limited-billing-access"
  path        = "/"
  description = "Allows limited billing access"
  policy      = data.aws_iam_policy_document.limited_billing_access.json

  tags = var.tags
}

module "billing_role_access" {
  count = var.create_billing_role && var.billing_source_account_id != "" ? 1 : 0

  source  = "trussworks/iam-cross-acct-dest/aws"
  version = "~> 4.0.0"

  iam_role_name     = "billing"
  source_account_id = var.billing_source_account_id
}
