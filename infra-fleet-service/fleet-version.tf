# =============================================================================
# FleetDM Auto-Version Management
# Automatically fetches the latest stable FleetDM release tag
# =============================================================================

terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Data: Fetch latest FleetDM release from GitHub
# -----------------------------------------------------------------------------

data "github_release" "fleet" {
  repository  = "fleet"
  owner       = "fleetdm"
  retrieve_by = "latest"
}

locals {
  # Strip the "fleet-v" or "v" prefix to get clean semver
  fleet_version = replace(replace(data.github_release.fleet.release_tag, "fleet-v", ""), "v", "")
  fleet_image   = "fleetdm/fleet:v${local.fleet_version}"
}

# -----------------------------------------------------------------------------
# Output: Use these in your ECS task def, Cloud Run, k8s, etc.
# -----------------------------------------------------------------------------

output "fleet_version" {
  description = "Current latest FleetDM version"
  value       = local.fleet_version
}

output "fleet_image" {
  description = "Full Docker image reference for FleetDM"
  value       = local.fleet_image
}

# =============================================================================
# OPTION A: If you're on ECS/Fargate, plug into your task definition like:
# =============================================================================
#
# resource "aws_ecs_task_definition" "fleet" {
#   family                   = "fleet"
#   requires_compatibilities = ["FARGATE"]
#   network_mode             = "awsvpc"
#   cpu                      = 512
#   memory                   = 1024
#   execution_role_arn       = aws_iam_role.fleet_execution.arn
#   task_role_arn            = aws_iam_role.fleet_task.arn
#
#   container_definitions = jsonencode([
#     {
#       name      = "fleet"
#       image     = local.fleet_image
#       essential = true
#       portMappings = [
#         {
#           containerPort = 8080
#           protocol      = "tcp"
#         }
#       ]
#       environment = [
#         { name = "FLEET_MYSQL_ADDRESS",  value = var.mysql_address },
#         { name = "FLEET_MYSQL_DATABASE", value = var.mysql_database },
#         { name = "FLEET_REDIS_ADDRESS",  value = var.redis_address },
#       ]
#       secrets = [
#         { name = "FLEET_MYSQL_PASSWORD", valueFrom = var.mysql_password_arn },
#       ]
#       logConfiguration = {
#         logDriver = "awslogs"
#         options = {
#           "awslogs-group"         = "/ecs/fleet"
#           "awslogs-region"        = var.aws_region
#           "awslogs-stream-prefix" = "fleet"
#         }
#       }
#     }
#   ])
# }

# =============================================================================
# OPTION B: Pin to a specific version with override variable
# Useful for controlled rollouts (don't always want bleeding edge)
# =============================================================================

locals {
  # Use override if set, otherwise use latest from GitHub
  fleet_effective_version = var.fleet_version_override != "" ? var.fleet_version_override : local.fleet_version
  fleet_effective_image   = "fleetdm/fleet:v${local.fleet_effective_version}"
}

output "fleet_effective_image" {
  description = "The image actually being deployed (respects override)"
  value       = local.fleet_effective_image
}
