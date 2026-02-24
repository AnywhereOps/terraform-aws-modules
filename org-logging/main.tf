#
# AWS Logs Bucket for Organization
#
# This module creates an S3 bucket for centralized logging
# (CloudTrail, Config, ALB, etc.) across the organization.
#

data "aws_organizations_organization" "current" {
  count = var.cloudtrail_accounts == null ? 1 : 0
}

locals {
  # If cloudtrail_accounts not specified, use all accounts in the org
  cloudtrail_accounts = var.cloudtrail_accounts != null ? var.cloudtrail_accounts : (
    length(data.aws_organizations_organization.current) > 0 ?
    concat(
      [data.aws_organizations_organization.current[0].id],
      data.aws_organizations_organization.current[0].accounts[*].id
    ) : []
  )
}

module "logs" {
  source  = "trussworks/logs/aws"
  version = "~> 18.0.0"

  s3_bucket_name = var.bucket_name

  default_allow    = var.default_allow
  allow_cloudtrail = var.allow_cloudtrail
  allow_config     = var.allow_config
  allow_alb        = var.allow_alb
  allow_nlb        = var.allow_nlb

  cloudtrail_accounts = local.cloudtrail_accounts
}
