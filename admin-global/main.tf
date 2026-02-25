data "aws_caller_identity" "current" {}

data "aws_iam_account_alias" "current" {}

#
# Logs
#

module "logs" {
  source = "git::https://github.com/trussworks/terraform-aws-logs.git?ref=v18.0.0"

  default_allow    = false
  allow_alb        = true
  allow_config     = true
  allow_cloudtrail = var.allow_cloudtrail

  s3_bucket_name = var.logging_bucket
}

#
# Config
#

module "config" {
  source = "git::https://github.com/trussworks/terraform-aws-config.git?ref=v8.0.0"

  config_name        = format("%s-config-%s", data.aws_iam_account_alias.current.account_alias, var.region)
  config_logs_bucket = module.logs.aws_logs_bucket

  aggregate_organization = true

  check_cloud_trail_encryption          = true
  check_cloud_trail_log_file_validation = true
  check_multi_region_cloud_trail        = true
}

# This module allows the users from the id account to assume the infra
# role in this account. See the README for more details at
# https://github.com/trussworks/terraform-aws-iam-cross-acct-dest
module "infra_role" {
  source = "git::https://github.com/trussworks/terraform-aws-iam-cross-acct-dest.git?ref=v4.0.0"

  iam_role_name     = "infra"
  source_account_id = var.account_id_id
}

resource "aws_iam_role_policy_attachment" "infra_role_policy" {
  role       = module.infra_role.iam_role_name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}
