output "rds" {
  description = "Aurora RDS cluster outputs"
  value       = module.rds
}

output "redis" {
  description = "ElastiCache Redis outputs"
  value       = module.redis
}

output "rds_security_group_id" {
  description = "Security group ID for RDS access"
  value       = aws_security_group.rds_sg.id
}

output "master_user_secret" {
  description = "Secrets Manager secret ARN for RDS master credentials. Use with :password:: suffix for ECS."
  value = {
    # This is the ARN (reference), NOT the actual password. Safe to output.
    # Usage in ECS: valueFrom = "${module.data.master_user_secret.arn}:password::"
    arn        = module.rds.cluster_master_user_secret[0].secret_arn
    kms_key_id = module.rds.cluster_master_user_secret[0].kms_key_id
  }
}

output "ssm_parameters" {
  description = "SSM parameter names for non-secret database connection details"
  value = {
    database_name        = aws_ssm_parameter.database_name.name
    database_user        = aws_ssm_parameter.database_user.name
    database_host        = aws_ssm_parameter.database_host.name
    database_reader_host = aws_ssm_parameter.database_reader_host.name
    # Password is now in Secrets Manager - use master_user_secret output
  }
}
