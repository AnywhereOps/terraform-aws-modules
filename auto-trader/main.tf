# ─── Data Sources ─────────────────────────────────────────────────────────────

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  prefix = "${var.project}-${var.environment}"
}

# ─── S3: Lambda Deploy Bucket ────────────────────────────────────────────────

module "lambda_builds_bucket" {
  source  = "trussworks/s3-private-bucket/aws"
  version = "~> 7.0"

  bucket         = "${local.prefix}-lambda-builds"
  logging_bucket = var.logging_bucket

  tags = {
    Name        = "${local.prefix}-lambda-builds"
    Environment = var.environment
    Project     = var.project
  }
}

# ─── Lambda: Signal Bot ──────────────────────────────────────────────────────

resource "aws_iam_policy" "signal_bot" {
  name = "${local.prefix}-signal-bot"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadUserSecrets"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:ListSecrets"
        ]
        Resource = "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${local.prefix}/users/*"
      },
      {
        Sid    = "WriteTradeLogs"
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.trade_log.arn,
          "${aws_dynamodb_table.trade_log.arn}/index/*"
        ]
      }
    ]
  })
}

module "signal_bot_lambda" {
  source = "trussworks/lambda/aws"

  name           = "${local.prefix}-bot"
  job_identifier = "signal-bot"
  runtime        = "python3.12"
  handler        = "handler.lambda_handler"

  s3_bucket = module.lambda_builds_bucket.id
  s3_key    = "signal-bot/latest.zip"

  timeout     = var.lambda_timeout
  memory_size = var.lambda_memory_size

  role_policy_arns_count = 1
  role_policy_arns       = [aws_iam_policy.signal_bot.arn]

  env_vars = {
    ENVIRONMENT        = var.environment
    DISCORD_PUBLIC_KEY = var.discord_public_key
    DISCORD_BOT_TOKEN  = var.discord_bot_token
    TRADE_LOG_TABLE    = aws_dynamodb_table.trade_log.name
    SECRETS_PREFIX     = "${local.prefix}/users"
  }
}

# ─── Lambda Function URL (Discord Interactions Endpoint) ──────────────────────

resource "aws_lambda_function_url" "signal_bot" {
  function_name      = module.signal_bot_lambda.lambda_function_name
  authorization_type = "NONE" # Discord signature verification handles auth
}

# ─── CloudWatch: Position Check Cron ─────────────────────────────────────────

resource "aws_cloudwatch_event_rule" "position_check" {
  name                = "${local.prefix}-position-check"
  description         = "Periodic position check during market hours"
  schedule_expression = var.position_check_schedule
}

resource "aws_cloudwatch_event_target" "position_check" {
  rule      = aws_cloudwatch_event_rule.position_check.name
  target_id = "signal-bot"
  arn       = module.signal_bot_lambda.lambda_function_arn
  input = jsonencode({
    source = "cron"
    action = "position_check"
  })
}

resource "aws_lambda_permission" "cron" {
  statement_id  = "AllowCloudWatchInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.signal_bot_lambda.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.position_check.arn
}

# ─── DynamoDB: Trade Log ─────────────────────────────────────────────────────

resource "aws_dynamodb_table" "trade_log" {
  name         = "${local.prefix}-trade-log"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "user_id"
  range_key    = "trade_id"

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "trade_id"
    type = "S"
  }

  attribute {
    name = "signal_id"
    type = "S"
  }

  global_secondary_index {
    name            = "signal-index"
    hash_key        = "signal_id"
    range_key       = "user_id"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }
}
