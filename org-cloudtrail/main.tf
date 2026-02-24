#
# AWS CloudTrail for Organization
#
# This module creates an organization-wide CloudTrail that logs
# all API activity across all member accounts.
#

module "cloudtrail" {
  source  = "trussworks/cloudtrail/aws"
  version = "~> 5.3.0"

  trail_name     = var.trail_name
  org_trail      = var.org_trail
  s3_bucket_name = var.s3_bucket_name
  s3_key_prefix  = var.s3_key_prefix

  # CloudWatch Logs integration
  cloudwatch_log_group_name = var.cloudwatch_log_group_name
  log_retention_days        = var.log_retention_days

  # KMS encryption
  encrypt_cloudtrail = var.encrypt_cloudtrail
}
