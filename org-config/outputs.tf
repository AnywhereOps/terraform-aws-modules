output "config_recorder_id" {
  description = "The ID of the AWS Config recorder"
  value       = module.config.aws_config_configuration_recorder_id
}
