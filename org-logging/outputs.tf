output "bucket_name" {
  description = "Name of the logs bucket"
  value       = module.logs.aws_logs_bucket
}

output "bucket_arn" {
  description = "ARN of the logs bucket"
  value       = module.logs.bucket_arn
}

output "bucket_id" {
  description = "ID of the logs bucket"
  value       = module.logs.aws_logs_bucket
}
