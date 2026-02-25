# GuardDuty admin configuration - only created when core_infra = true
#
# Because this account is the GuardDuty admin account, most of the GuardDuty
# configuration is done here, and all findings are consolidated in this account.

# GuardDuty is a region-based service, so for each region we want to get
# GuardDuty notifications for, we need to set up a set of resources.

resource "aws_guardduty_detector" "main_useast2" {
  count  = var.guardduty_enabled ? 1 : 0
  enable = true
}

resource "aws_guardduty_detector" "main_useast1" {
  count    = var.guardduty_enabled ? 1 : 0
  provider = aws.us-east-1
  enable   = true
}

# The organization configuration links other accounts to this one.
# Note: auto_enable = true means new accounts are automatically added as members.

resource "aws_guardduty_organization_configuration" "main_useast2" {
  count                            = var.guardduty_enabled ? 1 : 0
  auto_enable_organization_members = "ALL"
  detector_id                      = aws_guardduty_detector.main_useast2[0].id
}

resource "aws_guardduty_organization_configuration" "main_useast1" {
  count                            = var.guardduty_enabled ? 1 : 0
  provider                         = aws.us-east-1
  auto_enable_organization_members = "ALL"
  detector_id                      = aws_guardduty_detector.main_useast1[0].id
}

# GuardDuty notifications to Slack
module "guardduty_notifications_useast2" {
  count   = var.guardduty_enabled ? 1 : 0
  source = "git::https://github.com/trussworks/terraform-aws-guardduty-notifications.git?ref=v6.0.0"

  pagerduty_notifications = false
  slack_notifications     = true
  sns_topic_slack_arn     = aws_sns_topic.notify_slack_useast2[0].arn
}

module "guardduty_notifications_useast1" {
  count = var.guardduty_enabled ? 1 : 0

  providers = {
    aws = aws.us-east-1
  }

  source = "git::https://github.com/trussworks/terraform-aws-guardduty-notifications.git?ref=v6.0.0"

  pagerduty_notifications = false
  slack_notifications     = true
  sns_topic_slack_arn     = aws_sns_topic.notify_slack_useast1[0].arn
}
