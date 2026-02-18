# This file has configuration components for an RDS database instance
# for our sample webapp. We've separated them into this file to make it
# a little more clear how these components work. This example *is*
# PostgreSQL specific, but you can use a similar pattern with other
# RDS database types.

# It's pretty common for us to use T2 or T3 instances to run our RDS
# instances on; these are burstable CPU type instances which are
# especially useful for databases that tend to have uneven loads with
# high spikes when doing singular, high-impact transactions. If we are
# using these, we want to be able to set alarms based on whether we're
# eating into our CPU credit reserve, so we add some local variables to
# keep track of the per-instance maximums. You can find the source for
# these variables here: https://aws.amazon.com/rds/instance-types/

locals {
  # CPU credit maximums for burstable instance types
  cpu_credits_max = {
    "db.t3.small"   = 576
    "db.t3.medium"  = 576
    "db.t3.large"   = 864
    "db.t3.xlarge"  = 2304
    "db.t3.2xlarge" = 4608
    "db.t4g.micro"  = 288
    "db.t4g.small"  = 576
    "db.t4g.medium" = 576
    "db.t4g.large"  = 864
    "db.t4g.xlarge" = 2304
  }

  # Word-based replica naming for clarity in AWS console
  # (e.g., "aurora-one", "aurora-two" instead of "aurora-0", "aurora-1")
  replica_numbers = [
    "one", "two", "three", "four", "five", "six", "seven", "eight",
    "nine", "ten", "eleven", "twelve", "thirteen", "fourteen",
    "fifteen", "sixteen"
  ]

  # Generate instance map based on desired replica count
  # v10: DB parameter groups are now per-instance
  aurora_instances = {
    for index, replica_number in local.replica_numbers :
    replica_number => {
      db_parameter_group_name = var.rds_config.db_parameter_group_name == null ? aws_db_parameter_group.main[0].id : var.rds_config.db_parameter_group_name
    } if index < var.rds_config.replicas
  }
}

#
# Security Group
#

# Here we're going to create a security group that will lock down the
# RDS instance so that it can only talk to the containers running our
# service. We do this by only allowing things that are in the security
# group we created with the my-webapp ECS service module to talk to the
# database. This is better than trying to lock down to a specific VPC
# or subnet in the vast majority of cases.

# In general, we don't want anyone talking to the database *except* in
# programmatic ways -- ie, through the web service sitting in front of it
# or via a one-off migration container running from the same security
# group.

resource "aws_security_group" "rds_sg" {
  name        = format("rds-%s-%s", var.rds_config.name, var.environment)
  description = format("%s-%s RDS security group", var.rds_config.name, var.environment)
  vpc_id      = var.vpc_config.vpc_id
}

resource "aws_security_group_rule" "rds_allow_ecs_app_inbound" {
  for_each = toset(var.ecs_security_group_ids)

  description       = "Allow in ECS tasks"
  security_group_id = aws_security_group.rds_sg.id

  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = each.value
}

#
# RDS Connection SSM Parameters
#

# Here's one of the ways we can take advantage of the IAM policy we made in the
# main.tf to allow the ECS task to read parameters from SSM. We can define the
# connection settings for the database in SSM, and then use let the ECS task
# retrieve them there. Note the formatting of the parameter name; this is to
# align with the expectations of chamber (and make it easy to know what the
# parameters are for).

# For the database name and user, these aren't really "secrets" per se, so we
# can just take them as a variable and store them in code.

resource "aws_ssm_parameter" "database_name" {
  name        = format("/app-%s-%s/database-name", var.rds_config.name, var.environment)
  description = format("Database name for %s", var.rds_config.name)
  type        = "SecureString"
  value       = var.database_name
}

resource "aws_ssm_parameter" "database_user" {
  name        = format("/app-%s-%s/database-user", var.rds_config.name, var.environment)
  description = format("Database user for %s", var.rds_config.name)
  type        = "SecureString"
  value       = var.rds_config.master_username
}

# NOTE: Password is now managed by RDS in Secrets Manager (not SSM).
# The module.rds block below uses manage_master_user_password = true (default in v10+).
# Access the secret ARN via: module.rds.cluster_master_user_secret[0].secret_arn
# Previously this was added to AWS via chamber and gathered through SSM following the truss pattern
# data "aws_ssm_parameter" "database_password" {
#   name = format("/app-%s-%s/database-password", var.rds_config.name, var.environment)
# }
# For the database host, this is a little trickier -- we actually have to
# wait for the database to be created, then get the DNS for the RDS
# instance and plug it into SSM. This comes from the RDS module we use
# just a bit further down in this file.
resource "aws_ssm_parameter" "database_host" {
  name        = format("/app-%s-%s/database-host", var.rds_config.name, var.environment)
  description = format("Database host (writer) for %s", var.rds_config.name)
  type        = "SecureString"
  value       = module.rds.cluster_endpoint
}

# Reader endpoint for read replicas
resource "aws_ssm_parameter" "database_reader_host" {
  name        = format("/app-%s-%s/database-reader-host", var.rds_config.name, var.environment)
  description = format("Database host (reader) for %s", var.rds_config.name)
  type        = "SecureString"
  value       = module.rds.cluster_reader_endpoint
}

#
# RDS Instance
#

module "rds" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "~> 10.0"

  name                   = var.rds_config.name
  engine                 = "aurora-mysql"
  engine_version         = var.rds_config.engine_version
  cluster_instance_class = var.rds_config.instance_class  # v10: renamed from instance_class

  instances = local.aurora_instances

  serverlessv2_scaling_configuration = var.rds_config.serverless ? {
    min_capacity = var.rds_config.serverless_min_capacity
    max_capacity = var.rds_config.serverless_max_capacity
  } : {}

  vpc_id  = var.vpc_config.vpc_id
  subnets = var.vpc_config.subnets.database

  # Attach our manually-managed security group to RDS
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  # v10.0 BREAKING CHANGE: allowed_security_groups and allowed_cidr_blocks
  # are now security_group_ingress_rules with new structure.
  #
  # NOTE: Using VPC CIDR for ingress (Pattern A - SGs with resources).
  # TODO: Evaluate Gruntwork pattern (Pattern B - SGs in networking stack) for
  # tighter security group-based restrictions without circular dependencies.
  # See: https://github.com/gruntwork-io/terragrunt-infrastructure-catalog-example
  security_group_ingress_rules = merge(
    # Allow all traffic from within VPC (same pattern as Redis)
    {
      "vpc_cidr" = {
        cidr_ipv4   = var.vpc_config.vpc_cidr
        ip_protocol = "tcp"
        from_port   = 3306
        to_port     = 3306
      }
    },
    # Additional allowed security groups (optional)
    {
      for idx, sg_id in var.rds_config.allowed_security_groups :
      "allowed_sg_${idx}" => {
        referenced_security_group_id = sg_id
        ip_protocol                  = "tcp"
        from_port                    = 3306
        to_port                      = 3306
      }
    },
    # Additional allowed CIDR blocks (optional)
    {
      for idx, cidr in var.rds_config.allowed_cidr_blocks :
      "allowed_cidr_${idx}" => {
        cidr_ipv4   = cidr
        ip_protocol = "tcp"
        from_port   = 3306
        to_port     = 3306
      }
    }
  )

  # v10 renamed performance_insights and monitoring vars
  cluster_performance_insights_enabled = true
  cluster_monitoring_interval          = var.rds_config.monitoring_interval

  storage_encrypted = true
  apply_immediately = var.rds_config.apply_immediately

  # v10: Parameter group handling changed
  # - Set to null to use external groups (don't create via module)
  # - DB parameter groups are now per-instance (see local.aurora_instances)
  # - Cluster parameter group uses cluster_parameter_group_name
  db_parameter_group       = null  # We create externally
  cluster_parameter_group  = null  # We create externally
  cluster_parameter_group_name = var.rds_config.db_cluster_parameter_group_name == null ? aws_rds_cluster_parameter_group.main[0].id : var.rds_config.db_cluster_parameter_group_name

  enabled_cloudwatch_logs_exports = var.rds_config.enabled_cloudwatch_logs_exports
  master_username                 = var.rds_config.master_username

  # Password is managed by RDS in Secrets Manager (v10+ default).
  # manage_master_user_password = true (default, no need to specify)
  # TODO: For production, consider adding a custom KMS key:
  # master_user_secret_kms_key_id = aws_kms_key.rds_secret.arn

  database_name           = var.database_name
  skip_final_snapshot     = var.rds_config.skip_final_snapshot
  snapshot_identifier     = var.rds_config.snapshot_identifier
  backup_retention_period = var.rds_config.backup_retention_period
  restore_to_point_in_time = var.rds_config.restore_to_point_in_time

  preferred_maintenance_window = var.rds_config.preferred_maintenance_window

  tags = var.rds_config.cluster_tags
}
### Elasticache Redis

module "redis" {
  source  = "cloudposse/elasticache-redis/aws"
  version = "0.53.0"

  name                          = var.redis_config.name
  replication_group_id          = var.redis_config.replication_group_id == null ? var.redis_config.name : var.redis_config.replication_group_id
  elasticache_subnet_group_name = try(var.vpc_config.subnet_groups.elasticache, null) != null ? var.vpc_config.subnet_groups.elasticache : var.redis_config.name
  availability_zones            = var.vpc_config.azs
  vpc_id                        = var.vpc_config.vpc_id
  description                   = "Infra Redis"
  #allowed_security_group_ids = concat(var.redis_config.allowed_security_group_ids, module.byo-db.ecs.security_group)
  subnets                    = var.vpc_config.subnets.elasticache
  cluster_size               = var.redis_config.cluster_size
  instance_type              = var.redis_config.instance_type
  apply_immediately          = var.redis_config.apply_immediately
  automatic_failover_enabled = var.redis_config.automatic_failover_enabled
  engine_version             = var.redis_config.engine_version
  family                     = var.redis_config.family
  at_rest_encryption_enabled = var.redis_config.at_rest_encryption_enabled
  transit_encryption_enabled = var.redis_config.transit_encryption_enabled
  parameter                  = var.redis_config.parameter
  log_delivery_configuration = var.redis_config.log_delivery_configuration
  
  # NOTE: Using VPC CIDR for ingress (Pattern A - SGs with resources).
  # TODO: Evaluate Gruntwork pattern (Pattern B - SGs in networking stack) for
  # tighter security group-based restrictions without circular dependencies.
  # See: https://github.com/gruntwork-io/terragrunt-infrastructure-catalog-example
  allowed_cidr_blocks = [var.vpc_config.vpc_cidr]
  allowed_security_group_ids = concat(
    var.redis_config.allowed_security_group_ids,
    var.ecs_security_group_ids
  )
  #
  tags = var.redis_config.tags

}

###
# From Fleet for RDS Aurora
#
# NOTE: Parameter group names don't include environment. If we need separate
# dev/staging databases, use separate AWS accounts. Shared DB in sandbox is fine.
###

resource "aws_db_parameter_group" "main" {
  count       = var.rds_config.db_parameter_group_name == null ? 1 : 0
  name        = var.rds_config.name
  family      = "aurora-mysql8.0"
  description = "infra"

  dynamic "parameter" {
    for_each = var.rds_config.db_parameters
    content {
      name  = parameter.key
      value = parameter.value
    }
  }
}

resource "aws_rds_cluster_parameter_group" "main" {
  count       = var.rds_config.db_cluster_parameter_group_name == null ? 1 : 0
  name        = var.rds_config.name
  family      = "aurora-mysql8.0"
  description = "infra"

  dynamic "parameter" {
    for_each = var.rds_config.db_cluster_parameters
    content {
      name  = parameter.key
      value = parameter.value
    }
  }
}
# There are a number of other things you may want to add to the DB config
# in addition to these components. Consider things like:
#
# * The Truss RDS snapshot cleaner (https://github.com/trussworks/terraform-aws-rds-snapshot-cleaner)
module "rds-snapshot-cleaner" {
  count   = var.snapshot_cleaner_config.enabled ? 1 : 0
  source  = "trussworks/rds-snapshot-cleaner/aws"
  version = "4.0.0"

  cleaner_db_instance_identifier = module.rds.cluster_id
  cleaner_dry_run                = tostring(var.snapshot_cleaner_config.dry_run)
  cleaner_max_db_snapshot_count  = tostring(var.snapshot_cleaner_config.max_snapshot_count)
  cleaner_retention_days         = tostring(var.snapshot_cleaner_config.retention_days)
  cloudwatch_logs_retention_days = tostring(var.snapshot_cleaner_config.cloudwatch_logs_retention_days)
  environment                    = var.environment
  interval_minutes               = tostring(var.snapshot_cleaner_config.interval_minutes)
  s3_bucket                      = var.snapshot_cleaner_config.s3_bucket
  version_to_deploy              = "2.6"
}
# * Get SNS topic for alerts
  data "aws_sns_topic" "alerts" {
    name = var.sns_topic_name
  }

# * Cloudwatch alarms for running out of burstable CPU credits and storage space
  # TODO: Pin to commit SHA for production: ?ref=<commit-sha>
  module "rds_alarms" {
    source = "github.com/anywhereops/terraform-aws-rds-aurora-cloudwatch-alarms?ref=0.1.0"
    
    db_cluster_identifier = module.rds.cluster_id
    alarm_actions         = [data.aws_sns_topic.alerts.arn]  # Uses ARN
  }

# * Slack alerts for RDS events
  module "rds-notifications" {
    source         = "trussworks/rds-notifications/aws"
    version        = "4.0.0"
    
    sns_topic_name = var.sns_topic_name  # Uses name
  }
