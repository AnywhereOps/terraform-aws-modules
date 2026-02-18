output "interactions_endpoint_url" {
  description = "Set this as your Discord app's Interactions Endpoint URL"
  value       = aws_lambda_function_url.signal_bot.function_url
}

output "lambda_function_name" {
  description = "Name of the deployed Lambda function"
  value       = module.signal_bot_lambda.lambda_function_name
}

output "lambda_function_arn" {
  description = "ARN of the deployed Lambda function"
  value       = module.signal_bot_lambda.lambda_function_arn
}

output "trade_log_table_name" {
  description = "DynamoDB table name for trade logs"
  value       = aws_dynamodb_table.trade_log.name
}

output "trade_log_table_arn" {
  description = "DynamoDB table ARN for trade logs"
  value       = aws_dynamodb_table.trade_log.arn
}

output "s3_bucket" {
  description = "S3 bucket for Lambda deployment packages"
  value       = aws_s3_bucket.lambda_builds.id
}

output "secrets_prefix" {
  description = "Secrets Manager prefix for user credentials"
  value       = "${local.prefix}/users"
}
