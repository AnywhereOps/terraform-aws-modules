variable "name" {
  description = "Name for the ECS cluster"
  type        = string
  default     = "infra"
}

variable "environment" {
  description = "Environment (e.g., prod, sandbox)"
  type        = string
}

variable "ecs_cluster" {
  type = object({
    autoscaling_capacity_providers = optional(any, {})
    cluster_configuration = optional(any, {
      execute_command_configuration = {
        logging = "OVERRIDE"
        log_configuration = {
          cloud_watch_log_group_name = "/aws/ecs/infra"
        }
      }
    })
    cluster_name = optional(string, "infra")
    cluster_settings = optional(map(string), {
      "name" : "containerInsights",
      "value" : "enabled",
    })
    create                                = optional(bool, true)
    default_capacity_provider_use_fargate = optional(bool, true)
    fargate_capacity_providers = optional(any, {
      FARGATE = {
        default_capacity_provider_strategy = {
          weight = 100
        }
      }
      FARGATE_SPOT = {
        default_capacity_provider_strategy = {
          weight = 0
        }
      }
    })
    tags = optional(map(string))
  })
  default = {
    autoscaling_capacity_providers = {}
    cluster_configuration = {
      execute_command_configuration = {
        logging = "OVERRIDE"
        log_configuration = {
          cloud_watch_log_group_name = "/aws/ecs/infra"
        }
      }
    }
    cluster_settings = {
      "name" : "containerInsights",
      "value" : "enabled",
    }
    create                                = true
    default_capacity_provider_use_fargate = true
    fargate_capacity_providers = {
      FARGATE = {
        default_capacity_provider_strategy = {
          weight = 100
        }
      }
      FARGATE_SPOT = {
        default_capacity_provider_strategy = {
          weight = 0
        }
      }
    }
    tags = {}
  }
  description = "The config for the terraform-aws-modules/ecs/aws module"
  nullable    = false
}
