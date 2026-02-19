variable "vpc_config" {
  description = "VPC and networking configuration. All networking topology comes from here."
  type = object({
    vpc_id   = string
    vpc_cidr = string
    subnets = object({
      private     = list(string)
      database    = list(string)
      elasticache = list(string)
    })
    # Optional: pre-created subnet group names. If not provided, modules create their own.
    subnet_groups = optional(object({
      elasticache = optional(string)
    }), {})
    azs = list(string)
  })
}

variable "environment" {
  type        = string
  description = "Environment name (e.g., 'prod', 'staging'). Used for resource naming and SSM parameter paths."
}

variable "database_name" {
  type        = string
  description = "The name of the database to create in the Aurora cluster."
  default     = "infra"
}

variable "ecs_security_group_ids" {
  type        = list(string)
  description = "Security group IDs of ECS services that need database access. These SGs will be allowed ingress to the RDS security group."
  default     = []
}

variable "rds_config" {
  type = object({
    name           = optional(string, "infra")
    engine_version = optional(string, "8.0.mysql_aurora.3.07.1")
    instance_class = optional(string, "db.t4g.large")
    # Networking comes from vpc_config.subnets.database
    allowed_security_groups         = optional(list(string), [])
    allowed_cidr_blocks             = optional(list(string), [])
    apply_immediately               = optional(bool, false)
    monitoring_interval             = optional(number, 10)
    db_parameter_group_name         = optional(string)
    db_cluster_parameter_group_name = optional(string)

    # Instance-level parameters (applied per Aurora instance)
    # Recommended for PostgreSQL parity:
    #   {
    #     "slow_query_log"                = "1"      # Equivalent to log_min_duration_statement
    #     "long_query_time"               = "0.001"  # 1ms threshold (in seconds)
    #     "log_queries_not_using_indexes" = "1"      # Catch unoptimized queries
    #   }
    # Optional (expensive - logs every query):
    #     "general_log"                   = "1"      # Equivalent to log_statement = "all"
    db_parameters = optional(map(string), {})

    # Cluster-level parameters (applied to entire Aurora cluster)
    # Recommended for PostgreSQL parity:
    #   {
    #     "require_secure_transport" = "ON"  # Equivalent to rds.force_ssl = 1
    #   }
    # Optional (for connection/disconnection logging like log_connections/log_disconnections):
    #   {
    #     "server_audit_logging"     = "1"
    #     "server_audit_events"      = "CONNECT"
    #     "server_audit_excl_users"  = "rdsadmin"
    #   }
    db_cluster_parameters = optional(map(string), {})

    # CloudWatch log exports
    # Recommended: ["error", "slowquery"]
    # With audit enabled: ["error", "slowquery", "audit"]
    # With general log (expensive): ["error", "slowquery", "general"]
    enabled_cloudwatch_logs_exports = optional(list(string), ["error", "slowquery"])

    master_username              = optional(string, "infra")
    snapshot_identifier          = optional(string)
    cluster_tags                 = optional(map(string), {})
    preferred_maintenance_window = optional(string, "thu:23:00-fri:00:00")
    skip_final_snapshot          = optional(bool, false)
    backup_retention_period      = optional(number, 7)
    replicas                     = optional(number, 2)
    serverless                   = optional(bool, false)
    serverless_min_capacity      = optional(number, 2)
    serverless_max_capacity      = optional(number, 10)
    restore_to_point_in_time     = optional(map(string), {})
  })
  default = {
    name                            = "infra"
    engine_version                  = "8.0.mysql_aurora.3.07.1"
    instance_class                  = "db.t4g.large"
    allowed_security_groups         = []
    allowed_cidr_blocks             = []
    apply_immediately               = false
    monitoring_interval             = 10
    db_parameter_group_name         = null
    db_cluster_parameter_group_name = null

    # Recommended for production (PostgreSQL parity):
    # db_parameters = {
    #   "slow_query_log"                = "1"
    #   "long_query_time"               = "0.001"
    #   "log_queries_not_using_indexes" = "1"
    # }
    db_parameters = {}

    # Recommended for production (PostgreSQL parity):
    # db_cluster_parameters = {
    #   "require_secure_transport" = "ON"
    # }
    db_cluster_parameters = {}

    enabled_cloudwatch_logs_exports = ["error", "slowquery"]

    master_username              = "infra"
    snapshot_identifier          = null
    cluster_tags                 = {}
    preferred_maintenance_window = "thu:23:00-fri:00:00"
    skip_final_snapshot          = false
    backup_retention_period      = 7
    replicas                     = 2
    serverless                   = false
    serverless_min_capacity      = 2
    serverless_max_capacity      = 10
    restore_to_point_in_time     = {}
  }
  description = "The config for the terraform-aws-modules/rds-aurora/aws module"
  nullable    = false
}

variable "redis_config" {
  description = "Redis-specific configuration. Networking comes from vpc_config."
  type = object({
    name                       = optional(string, "infra")
    replication_group_id       = optional(string)
    allowed_security_group_ids = optional(list(string), [])
    cluster_size               = optional(number, 3)
    instance_type              = optional(string, "cache.m5.large")
    apply_immediately          = optional(bool, false) # Safe default for production
    # Enables automatic promotion of replica to primary on failure. Requires cluster_size >= 2.
    # Set to false for dev/sandbox to reduce costs. Enable for production HA.
    automatic_failover_enabled = optional(bool, true)
    engine_version             = optional(string, "6.x")
    family                     = optional(string, "redis6.x")
    at_rest_encryption_enabled = optional(bool, true)
    transit_encryption_enabled = optional(bool, true)
    parameter = optional(list(object({
      name  = string
      value = string
    })), [])
    log_delivery_configuration = optional(list(map(any)), [])
    tags                       = optional(map(string), {})
  })
  default = {}
}

variable "snapshot_cleaner_config" {
  description = "Configuration for the Trussworks RDS snapshot cleaner Lambda. Set enabled=false to disable."
  type = object({
    enabled                        = optional(bool, true)
    dry_run                        = optional(bool, false)
    max_snapshot_count             = optional(number, 50)
    retention_days                 = optional(number, 30)
    cloudwatch_logs_retention_days = optional(number, 90)
    interval_minutes               = optional(number, 5)
    # Trussworks hosts Lambda builds in their public S3 bucket
    s3_bucket = optional(string, "lambda-builds-us-east-1")
  })
  default = {}
}

variable "sns_topic_name" {
  description = "SNS topic name for RDS alerts and notifications"
  type        = string
  default     = "notify-slack"
}