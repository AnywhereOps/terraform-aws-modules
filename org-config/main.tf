#
# AWS Config for Organization
#
# Wraps the Trussworks config module with sensible defaults
# for organization-wide compliance monitoring.
#

data "aws_iam_account_alias" "current" {}
data "aws_region" "current" {}

locals {
  config_name = coalesce(
    var.config_name,
    "${data.aws_iam_account_alias.current.account_alias}-config-${data.aws_region.current.name}"
  )
}

module "config" {
  source  = "trussworks/config/aws"
  version = "~> 8.0"

  config_name        = local.config_name
  config_logs_bucket = var.config_logs_bucket

  aggregate_organization = var.aggregate_organization

  # CloudTrail compliance checks
  check_cloud_trail_encryption          = var.check_cloud_trail_encryption
  check_cloud_trail_log_file_validation = var.check_cloud_trail_log_file_validation
  check_multi_region_cloud_trail        = var.check_multi_region_cloud_trail

  # Root account check (only enable in org-root account)
  check_root_account_mfa_enabled = var.check_root_account_mfa_enabled

  tags = var.tags
}
