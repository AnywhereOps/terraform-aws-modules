# infra-data

RDS database module for AnywhereOps infrastructure.

## API

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.18 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.18 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_rds"></a> [rds](#module\_rds) | terraform-aws-modules/rds-aurora/aws | ~> 10.0 |
| <a name="module_rds-notifications"></a> [rds-notifications](#module\_rds-notifications) | trussworks/rds-notifications/aws | 4.0.0 |
| <a name="module_rds-snapshot-cleaner"></a> [rds-snapshot-cleaner](#module\_rds-snapshot-cleaner) | trussworks/rds-snapshot-cleaner/aws | 4.0.0 |
| <a name="module_rds_alarms"></a> [rds\_alarms](#module\_rds\_alarms) | github.com/anywhereops/terraform-aws-rds-aurora-cloudwatch-alarms | 0.1.0 |
| <a name="module_redis"></a> [redis](#module\_redis) | cloudposse/elasticache-redis/aws | 0.53.0 |

## Resources

| Name | Type |
|------|------|
| [aws_db_parameter_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_parameter_group) | resource |
| [aws_rds_cluster_parameter_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster_parameter_group) | resource |
| [aws_security_group.rds_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.rds_allow_ecs_app_inbound](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_ssm_parameter.database_host](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.database_name](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.database_reader_host](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.database_user](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_sns_topic.alerts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/sns_topic) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., 'prod', 'staging'). Used for resource naming and SSM parameter paths. | `string` | n/a | yes |
| <a name="input_vpc_config"></a> [vpc\_config](#input\_vpc\_config) | VPC and networking configuration. All networking topology comes from here. | <pre>object({<br/>    vpc_id   = string<br/>    vpc_cidr = string<br/>    subnets = object({<br/>      private     = list(string)<br/>      database    = list(string)<br/>      elasticache = list(string)<br/>    })<br/>    # Optional: pre-created subnet group names. If not provided, modules create their own.<br/>    subnet_groups = optional(object({<br/>      elasticache = optional(string)<br/>    }), {})<br/>    azs = list(string)<br/>  })</pre> | n/a | yes |
| <a name="input_database_name"></a> [database\_name](#input\_database\_name) | The name of the database to create in the Aurora cluster. | `string` | `"infra"` | no |
| <a name="input_ecs_security_group_ids"></a> [ecs\_security\_group\_ids](#input\_ecs\_security\_group\_ids) | Security group IDs of ECS services that need database access. These SGs will be allowed ingress to the RDS security group. | `list(string)` | `[]` | no |
| <a name="input_rds_config"></a> [rds\_config](#input\_rds\_config) | The config for the terraform-aws-modules/rds-aurora/aws module | <pre>object({<br/>    name           = optional(string, "infra")<br/>    engine_version = optional(string, "8.0.mysql_aurora.3.07.1")<br/>    instance_class = optional(string, "db.t4g.large")<br/>    # Networking comes from vpc_config.subnets.database<br/>    allowed_security_groups         = optional(list(string), [])<br/>    allowed_cidr_blocks             = optional(list(string), [])<br/>    apply_immediately               = optional(bool, false)<br/>    monitoring_interval             = optional(number, 10)<br/>    db_parameter_group_name         = optional(string)<br/>    db_cluster_parameter_group_name = optional(string)<br/><br/>    # Instance-level parameters (applied per Aurora instance)<br/>    # Recommended for PostgreSQL parity:<br/>    #   {<br/>    #     "slow_query_log"                = "1"      # Equivalent to log_min_duration_statement<br/>    #     "long_query_time"               = "0.001"  # 1ms threshold (in seconds)<br/>    #     "log_queries_not_using_indexes" = "1"      # Catch unoptimized queries<br/>    #   }<br/>    # Optional (expensive - logs every query):<br/>    #     "general_log"                   = "1"      # Equivalent to log_statement = "all"<br/>    db_parameters = optional(map(string), {})<br/><br/>    # Cluster-level parameters (applied to entire Aurora cluster)<br/>    # Recommended for PostgreSQL parity:<br/>    #   {<br/>    #     "require_secure_transport" = "ON"  # Equivalent to rds.force_ssl = 1<br/>    #   }<br/>    # Optional (for connection/disconnection logging like log_connections/log_disconnections):<br/>    #   {<br/>    #     "server_audit_logging"     = "1"<br/>    #     "server_audit_events"      = "CONNECT"<br/>    #     "server_audit_excl_users"  = "rdsadmin"<br/>    #   }<br/>    db_cluster_parameters = optional(map(string), {})<br/><br/>    # CloudWatch log exports<br/>    # Recommended: ["error", "slowquery"]<br/>    # With audit enabled: ["error", "slowquery", "audit"]<br/>    # With general log (expensive): ["error", "slowquery", "general"]<br/>    enabled_cloudwatch_logs_exports = optional(list(string), ["error", "slowquery"])<br/><br/>    master_username              = optional(string, "infra")<br/>    snapshot_identifier          = optional(string)<br/>    cluster_tags                 = optional(map(string), {})<br/>    preferred_maintenance_window = optional(string, "thu:23:00-fri:00:00")<br/>    skip_final_snapshot          = optional(bool, false)<br/>    backup_retention_period      = optional(number, 7)<br/>    replicas                     = optional(number, 2)<br/>    serverless                   = optional(bool, false)<br/>    serverless_min_capacity      = optional(number, 2)<br/>    serverless_max_capacity      = optional(number, 10)<br/>    restore_to_point_in_time     = optional(map(string), {})<br/>  })</pre> | <pre>{<br/>  "allowed_cidr_blocks": [],<br/>  "allowed_security_groups": [],<br/>  "apply_immediately": false,<br/>  "backup_retention_period": 7,<br/>  "cluster_tags": {},<br/>  "db_cluster_parameter_group_name": null,<br/>  "db_cluster_parameters": {},<br/>  "db_parameter_group_name": null,<br/>  "db_parameters": {},<br/>  "enabled_cloudwatch_logs_exports": [<br/>    "error",<br/>    "slowquery"<br/>  ],<br/>  "engine_version": "8.0.mysql_aurora.3.07.1",<br/>  "instance_class": "db.t4g.large",<br/>  "master_username": "infra",<br/>  "monitoring_interval": 10,<br/>  "name": "infra",<br/>  "preferred_maintenance_window": "thu:23:00-fri:00:00",<br/>  "replicas": 2,<br/>  "restore_to_point_in_time": {},<br/>  "serverless": false,<br/>  "serverless_max_capacity": 10,<br/>  "serverless_min_capacity": 2,<br/>  "skip_final_snapshot": false,<br/>  "snapshot_identifier": null<br/>}</pre> | no |
| <a name="input_redis_config"></a> [redis\_config](#input\_redis\_config) | Redis-specific configuration. Networking comes from vpc\_config. | <pre>object({<br/>    name                       = optional(string, "infra")<br/>    replication_group_id       = optional(string)<br/>    allowed_security_group_ids = optional(list(string), [])<br/>    cluster_size               = optional(number, 3)<br/>    instance_type              = optional(string, "cache.m5.large")<br/>    apply_immediately          = optional(bool, false) # Safe default for production<br/>    # Enables automatic promotion of replica to primary on failure. Requires cluster_size >= 2.<br/>    # Set to false for dev/sandbox to reduce costs. Enable for production HA.<br/>    automatic_failover_enabled = optional(bool, true)<br/>    engine_version             = optional(string, "6.x")<br/>    family                     = optional(string, "redis6.x")<br/>    at_rest_encryption_enabled = optional(bool, true)<br/>    transit_encryption_enabled = optional(bool, true)<br/>    parameter = optional(list(object({<br/>      name  = string<br/>      value = string<br/>    })), [])<br/>    log_delivery_configuration = optional(list(map(any)), [])<br/>    tags                       = optional(map(string), {})<br/>  })</pre> | `{}` | no |
| <a name="input_snapshot_cleaner_config"></a> [snapshot\_cleaner\_config](#input\_snapshot\_cleaner\_config) | Configuration for the Trussworks RDS snapshot cleaner Lambda. Set enabled=false to disable. | <pre>object({<br/>    enabled                        = optional(bool, true)<br/>    dry_run                        = optional(bool, false)<br/>    max_snapshot_count             = optional(number, 50)<br/>    retention_days                 = optional(number, 30)<br/>    cloudwatch_logs_retention_days = optional(number, 90)<br/>    interval_minutes               = optional(number, 5)<br/>    # Trussworks hosts Lambda builds in their public S3 bucket<br/>    s3_bucket = optional(string, "lambda-builds-us-east-1")<br/>  })</pre> | `{}` | no |
| <a name="input_sns_topic_name"></a> [sns\_topic\_name](#input\_sns\_topic\_name) | SNS topic name for RDS alerts and notifications | `string` | `"notify-slack"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_master_user_secret"></a> [master\_user\_secret](#output\_master\_user\_secret) | Secrets Manager secret ARN for RDS master credentials. Use with :password:: suffix for ECS. |
| <a name="output_rds"></a> [rds](#output\_rds) | Aurora RDS cluster outputs |
| <a name="output_rds_security_group_id"></a> [rds\_security\_group\_id](#output\_rds\_security\_group\_id) | Security group ID for RDS access |
| <a name="output_redis"></a> [redis](#output\_redis) | ElastiCache Redis outputs |
| <a name="output_ssm_parameters"></a> [ssm\_parameters](#output\_ssm\_parameters) | SSM parameter names for non-secret database connection details |
<!-- END_TF_DOCS -->

## Development

See the root [README.md](../README.md) for development instructions.
