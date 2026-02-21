variable "alb_health_check_path" {
  description = "Path for ALB health check"
  type        = string
  default     = "/healthz"
}

variable "alb_health_check_interval" {
  description = "Interval for ALB health check (in seconds)"
  type        = number
  default     = 30
}

variable "alb_health_check_timeout" {
  description = "Timeout for ALB health check (in seconds)"
  type        = number
  default     = 5
}

variable "alb_logs_bucket" {
  description = "S3 bucket for ALB logs"
  type        = string
}

variable "alb_subnets" {
  description = "Subnets for ALB"
  type        = list(string)
}

variable "container_port" {
  description = "Port Fleet container listens on (Fleet uses 8080 by default)"
  type        = number
  default     = 8080
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS instance (in GB)"
  type        = number
  default     = 20
}

variable "db_backup_retention" {
  description = "RDS backup retention (in days)"
  type        = number
  default     = 7
}

variable "db_instance_class" {
  description = "Instance class for RDS instance"
  type        = string
  default     = "db.t3.small"
}

variable "db_multi_az" {
  description = "Multi AZ setting for RDS"
  type        = bool
  default     = false
}

variable "db_name" {
  description = "Name for database on RDS instance"
  type        = string
  default     = "my_webapp"
}

variable "db_subnet_group_name" {
  description = "DB subnet group name"
  type        = string
}

variable "db_subnets" {
  description = "List of DB subnets"
  type        = list(string)
}

variable "db_user" {
  description = "User for accessing RDS instance"
  type        = string
  default     = "master"
}

variable "dns_zone_id" {
  description = "Zone ID for DNS"
  type        = string
}

variable "domain_name" {
  description = "Outward facing FQDN for service"
  type        = string
}

variable "ecs_subnets" {
  description = "Subnets for ECS service"
  type        = list(string)
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "final_snapshot_identifier" {
  description = "Final RDS snapshot identifier"
  type        = string
  default     = ""
}

variable "tasks_desired_count" {
  description = "Number of ECS tasks to run"
  type        = number
  default     = 1
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster (from stacks/ecs-cluster)"
  type        = string
}

variable "cloudwatch_logs_retention_days" {
  description = "CloudWatch Logs retention in days"
  type        = number
  default     = 90
}

# Fleet configuration - copied from byo-ecs/variables.tf
# Removed: networking, loadbalancer, iam, autoscaling (handled by Trussworks or separate resources)
# Removed: software_installers (out of scope)
variable "cross_account_secret_policies" {
  description = "Map of secret names to cross-account role ARNs allowed to read them via resource policy."
  type        = map(string)
  default     = {}
}

variable "fleet_config" {
  type = object({
    task_mem                     = optional(number, null)
    task_cpu                     = optional(number, null)
    mem                          = optional(number, 512)
    cpu                          = optional(number, 256)
    pid_mode                     = optional(string, null)
    image                        = optional(string, "fleetdm/fleet:v4.78.0")
    family                       = optional(string, "fleet")
    sidecars                     = optional(list(any), [])
    depends_on                   = optional(list(any), [])
    mount_points                 = optional(list(any), [])
    volumes                      = optional(list(any), [])
    extra_environment_variables  = optional(map(string), {})
    extra_iam_policies           = optional(list(string), [])
    extra_execution_iam_policies = optional(list(string), [])
    extra_secrets                = optional(map(string), {})
    security_group_name          = optional(string, "fleet")
    iam_role_arn                 = optional(string, null)
    repository_credentials       = optional(string, "")
    private_key_secret_name      = optional(string, "fleet-server-private-key")
    service = optional(object({
      name = optional(string, "fleet")
      }), {
      name = "fleet"
    })
    database = object({
      password_secret_arn = string
      user                = string
      database            = string
      address             = string
      rr_address          = optional(string, null)
    })
    redis = object({
      address = string
      use_tls = optional(bool, true)
    })
    awslogs = optional(object({
      name      = optional(string, null)
      region    = optional(string, null)
      create    = optional(bool, true)
      prefix    = optional(string, "fleet")
      retention = optional(number, 5)
      }), {
      name      = null
      region    = null
      prefix    = "fleet"
      retention = 5
    })
    loadbalancer = object({
      arn = string
    })
    extra_load_balancers = optional(list(any), [])
    networking = object({
      subnets         = optional(list(string), null)
      security_groups = optional(list(string), null)
      ingress_sources = object({
        cidr_blocks      = optional(list(string), [])
        ipv6_cidr_blocks = optional(list(string), [])
        security_groups  = optional(list(string), [])
        prefix_list_ids  = optional(list(string), [])
      })
    })
    autoscaling = optional(object({
      max_capacity                 = optional(number, 5)
      min_capacity                 = optional(number, 1)
      memory_tracking_target_value = optional(number, 80)
      cpu_tracking_target_value    = optional(number, 80)
      }), {
      max_capacity                 = 5
      min_capacity                 = 1
      memory_tracking_target_value = 80
      cpu_tracking_target_value    = 80
    })
    iam = optional(object({
      role = optional(object({
        name        = optional(string, "fleet-role")
        policy_name = optional(string, "fleet-iam-policy")
        }), {
        name        = "fleet-role"
        policy_name = "fleet-iam-policy"
      })
      execution = optional(object({
        name        = optional(string, "fleet-execution-role")
        policy_name = optional(string, "fleet-execution-role")
        }), {
        name        = "fleet-execution-role"
        policy_name = "fleet-iam-policy-execution"
      })
      }), {
      name = "fleetdm-execution-role"
    })
    software_installers = optional(object({
      bucket_name      = optional(string, null)
      bucket_arn       = optional(string, null)
      s3_object_prefix = optional(string, "")
      }), {
      bucket_name      = null
      bucket_arn       = null
      s3_object_prefix = ""
    })
  })
  default = {
    task_mem                     = null
    task_cpu                     = null
    mem                          = 512
    cpu                          = 256
    pid_mode                     = null
    image                        = "fleetdm/fleet:v4.78.0"
    family                       = "fleet"
    sidecars                     = []
    depends_on                   = []
    mount_points                 = []
    volumes                      = []
    extra_environment_variables  = {}
    extra_iam_policies           = []
    extra_execution_iam_policies = []
    extra_secrets                = {}
    security_group_name          = "fleet"
    iam_role_arn                 = null
    repository_credentials       = ""
    private_key_secret_name      = "fleet-server-private-key"
    service = {
      name = "fleet"
    }
    database = {
      password_secret_arn = null
      user                = null
      database            = null
      address             = null
      rr_address          = null
    }
    redis = {
      address = null
      use_tls = true
    }
    awslogs = {
      name      = null
      region    = null
      create    = true
      prefix    = "fleet"
      retention = 5
    }
    loadbalancer = {
      arn = null
    }
    extra_load_balacners = []
    networking = {
      subnets         = null
      security_groups = null
      ingress_sources = {
        cidr_blocks      = []
        ipv6_cidr_blocks = []
        security_groups  = []
        prefix_list_ids  = []
      }
    }
    autoscaling = {
      max_capacity                 = 5
      min_capacity                 = 1
      memory_tracking_target_value = 80
      cpu_tracking_target_value    = 80
    }
    iam = {
      role = {
        name        = "fleet-role"
        policy_name = "fleet-iam-policy"
      }
      execution = {
        name        = "fleet-execution-role"
        policy_name = "fleet-iam-policy-execution"
      }
    }
    software_installers = {
      bucket_name      = null
      bucket_arn       = null
      s3_object_prefix = ""
    }
  }
  description = "The configuration object for Fleet itself. Fields that default to null will have their respective resources created if not specified."
  nullable    = false
}

