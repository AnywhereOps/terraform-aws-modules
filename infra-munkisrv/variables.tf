# -----------------------------------------------------------------------------
# Required
# -----------------------------------------------------------------------------

variable "environment" {
  description = "Environment name (e.g., prod, staging)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "ecs_subnets" {
  description = "Subnets for ECS service"
  type        = list(string)
}

variable "alb_subnets" {
  description = "Subnets for ALB"
  type        = list(string)
}

variable "alb_logs_bucket" {
  description = "S3 bucket for ALB logs"
  type        = string
}

variable "dns_zone_id" {
  description = "Route53 zone ID for DNS records"
  type        = string
}

variable "domain_name" {
  description = "Domain name for munkisrv (e.g., munki.anywhereops.ai)"
  type        = string
}

# -----------------------------------------------------------------------------
# CloudFront / Packages integration
# -----------------------------------------------------------------------------

variable "cloudfront_url" {
  description = "CloudFront distribution URL from infra-packages"
  type        = string
}

variable "signing_secret_arn" {
  description = "Secrets Manager ARN containing CloudFront signing credentials (cloudfront_public_key_id + private_key)"
  type        = string
}

# -----------------------------------------------------------------------------
# Container
# -----------------------------------------------------------------------------

variable "ecr_repo_name" {
  description = "ECR repository name for munkisrv"
  type        = string
  default     = "munkisrv"
}

variable "image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}

variable "container_port" {
  description = "Port munkisrv listens on"
  type        = number
  default     = 3000
}

variable "cpu" {
  description = "CPU units for container"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Memory for container (MB)"
  type        = number
  default     = 512
}

variable "tasks_desired_count" {
  description = "Number of ECS tasks"
  type        = number
  default     = 1
}

# -----------------------------------------------------------------------------
# TLS / mTLS (deferred)
# -----------------------------------------------------------------------------

variable "mtls_enabled" {
  description = "Enable mTLS for Munki client authentication (not yet implemented)"
  type        = bool
  default     = false
}

variable "mtls_ca_secret_arn" {
  description = "Secrets Manager ARN containing the CA cert for client verification"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Optional
# -----------------------------------------------------------------------------

variable "cloudwatch_logs_retention_days" {
  description = "CloudWatch Logs retention in days"
  type        = number
  default     = 90
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
