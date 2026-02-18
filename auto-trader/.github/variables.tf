variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "project" {
  description = "Project name, used as prefix for all resources"
  type        = string
  default     = "signal-bot"
}

variable "discord_public_key" {
  description = "Discord application public key (for signature verification)"
  type        = string
  sensitive   = true
}

variable "discord_bot_token" {
  description = "Discord bot token (for posting follow-up messages)"
  type        = string
  sensitive   = true
}

variable "discord_guild_id" {
  description = "Discord server ID where slash commands are registered"
  type        = string
}

variable "lambda_memory_size" {
  description = "Lambda memory in MB"
  type        = number
  default     = 512
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 120
}

variable "position_check_schedule" {
  description = "Cron expression for position check (default: every 30 min during market hours ET)"
  type        = string
  default     = "cron(0/30 13-20 ? * MON-FRI *)"
}
