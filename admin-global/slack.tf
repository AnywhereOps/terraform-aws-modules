# Slack notifications - only created when core_infra = true
#
# This SSM parameter contains our Slack webhook URL that we've added
# manually so that it can be safely pulled here; it's a secret, so we
# don't want to leave it in code anywhere.

data "aws_ssm_parameter" "slack_webhook_url" {
  count = var.core_infra ? 1 : 0
  name  = "/slack/webhook/url/anywhereops-infra"
}

#
# SNS Topics
#

resource "aws_sns_topic" "notify_slack_useast1" {
  count    = var.core_infra ? 1 : 0
  provider = aws.us-east-1
  name     = "notify-slack"
}

resource "aws_sns_topic" "notify_slack_useast2" {
  count = var.core_infra ? 1 : 0
  name  = "notify-slack"
}

#
# IAM Policies
#

data "aws_iam_policy_document" "notify_slack_topic_policy_useast1" {
  count = var.core_infra ? 1 : 0

  statement {
    sid = "__default_statement_ID"
    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"
      values   = [data.aws_caller_identity.current.account_id]
    }
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = [aws_sns_topic.notify_slack_useast1[0].arn]
  }

  statement {
    sid    = "allow-cloudwatch"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.notify_slack_useast1[0].arn]
  }
}

data "aws_iam_policy_document" "notify_slack_topic_policy_useast2" {
  count = var.core_infra ? 1 : 0

  statement {
    sid = "__default_statement_ID"
    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"
      values   = [data.aws_caller_identity.current.account_id]
    }
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = [aws_sns_topic.notify_slack_useast2[0].arn]
  }

  statement {
    sid    = "allow-cloudwatch"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.notify_slack_useast2[0].arn]
  }
}

#
# SNS Topic Policies
#

resource "aws_sns_topic_policy" "notify_slack_useast1" {
  count    = var.core_infra ? 1 : 0
  provider = aws.us-east-1
  arn      = aws_sns_topic.notify_slack_useast1[0].arn
  policy   = data.aws_iam_policy_document.notify_slack_topic_policy_useast1[0].json
}

resource "aws_sns_topic_policy" "notify_slack_useast2" {
  count  = var.core_infra ? 1 : 0
  arn    = aws_sns_topic.notify_slack_useast2[0].arn
  policy = data.aws_iam_policy_document.notify_slack_topic_policy_useast2[0].json
}

#
# Lambda - Slack Notifiers
#

module "notify_slack_useast1" {
  count = var.core_infra ? 1 : 0

  providers = {
    aws = aws.us-east-1
  }

  source  = "terraform-aws-modules/notify-slack/aws"
  version = "~> 7.2.0"

  lambda_function_name = "notify_slack_useast1"
  create_sns_topic     = false
  sns_topic_name       = aws_sns_topic.notify_slack_useast1[0].name

  slack_webhook_url = data.aws_ssm_parameter.slack_webhook_url[0].value
  slack_channel     = "anywhereops-infra"
  slack_username    = "aws-org-alerts"
}

module "notify_slack_useast2" {
  count = var.core_infra ? 1 : 0

  source  = "terraform-aws-modules/notify-slack/aws"
  version = "~> 7.2.0"

  lambda_function_name = "notify_slack_useast2"
  create_sns_topic     = false
  sns_topic_name       = aws_sns_topic.notify_slack_useast2[0].name

  slack_webhook_url = data.aws_ssm_parameter.slack_webhook_url[0].value
  slack_channel     = "anywhereops-infra"
  slack_username    = "aws-org-alerts"
}
