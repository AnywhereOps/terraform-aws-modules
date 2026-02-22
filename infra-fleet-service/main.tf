# =============================================================================
# Fleet Service Module
# Creates ALB, ECS service, task definition, IAM roles, and supporting infra
# =============================================================================

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

data "aws_secretsmanager_secret" "fleet_license" {
  name = "fleet-license"
}

# =============================================================================
# Locals
# =============================================================================

locals {
  # Environment variables for container
  environment = [for k, v in var.fleet_config.extra_environment_variables : {
    name  = k
    value = v
  }]

  # Secrets including license
  secrets = [for k, v in merge(
    { "FLEET_LICENSE_KEY" = data.aws_secretsmanager_secret.fleet_license.arn },
    var.fleet_config.extra_secrets
  ) : {
    name      = k
    valueFrom = v
  }]

  # Repository credentials for private registries
  repository_credentials = var.fleet_config.repository_credentials != "" ? {
    credentialsParameter = var.fleet_config.repository_credentials
  } : null
}

# =============================================================================
# ACM Certificate
# =============================================================================

resource "aws_acm_certificate" "fleet" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "fleet_acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.fleet.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = var.dns_zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "fleet" {
  certificate_arn         = aws_acm_certificate.fleet.arn
  validation_record_fqdns = [for record in aws_route53_record.fleet_acm_validation : record.fqdn]
}

# =============================================================================
# Application Load Balancer
# =============================================================================

module "alb_fleet" {
  source  = "trussworks/alb-web-containers/aws"
  version = "~> 10.0.0"

  name           = "fleet"
  environment    = var.environment
  logs_s3_bucket = var.alb_logs_bucket
  logs_s3_prefix = "alb"

  alb_ssl_policy              = "ELBSecurityPolicy-TLS-1-2-2017-01"
  alb_default_certificate_arn = aws_acm_certificate_validation.fleet.certificate_arn
  alb_certificate_arns        = []
  alb_vpc_id                  = var.vpc_id
  alb_subnet_ids              = var.alb_subnets

  container_protocol = "HTTP"
  container_port     = var.container_port

  health_check_path     = var.alb_health_check_path
  health_check_interval = var.alb_health_check_interval
  health_check_timeout  = var.alb_health_check_timeout

  target_group_name = format("fleet-%s-%s", var.environment, var.container_port)

  allow_public_https = true
  allow_public_http  = true
}

resource "aws_route53_record" "fleet" {
  name    = var.domain_name
  zone_id = var.dns_zone_id
  type    = "A"

  alias {
    name                   = module.alb_fleet.alb_dns_name
    zone_id                = module.alb_fleet.alb_zone_id
    evaluate_target_health = false
  }
}

# =============================================================================
# CloudWatch Logs
# =============================================================================

data "aws_iam_policy_document" "cloudwatch_logs_allow_kms" {
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "Allow logs KMS access"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
    }

    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = ["*"]
  }
}

resource "aws_kms_key" "fleet_logs" {
  description         = "Key for Fleet ECS log encryption"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.cloudwatch_logs_allow_kms.json
}

resource "aws_cloudwatch_log_group" "fleet" {
  name              = "ecs-tasks-fleet-${var.environment}"
  retention_in_days = var.cloudwatch_logs_retention_days
  kms_key_id        = aws_kms_key.fleet_logs.arn
}

# =============================================================================
# Secrets Manager - Fleet Server Private Key
# =============================================================================

resource "random_password" "fleet_server_private_key" {
  length  = 32
  special = true
}

resource "aws_secretsmanager_secret" "fleet_server_private_key" {
  name                    = "fleet-${var.environment}-server-private-key"
  recovery_window_in_days = 0

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_secretsmanager_secret_version" "fleet_server_private_key" {
  secret_id     = aws_secretsmanager_secret.fleet_server_private_key.id
  secret_string = random_password.fleet_server_private_key.result
}

# Cross-account secret policies
data "aws_secretsmanager_secret" "cross_account" {
  for_each = var.cross_account_secret_policies
  name     = each.key
}

resource "aws_secretsmanager_secret_policy" "cross_account" {
  for_each   = var.cross_account_secret_policies
  secret_arn = data.aws_secretsmanager_secret.cross_account[each.key].arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCrossAccountAccess"
      Effect    = "Allow"
      Principal = { AWS = each.value }
      Action    = "secretsmanager:GetSecretValue"
      Resource  = "*"
    }]
  })
}

# =============================================================================
# ECS Cluster Reference
# =============================================================================

data "aws_ecs_cluster" "main" {
  cluster_name = var.ecs_cluster_name
}

# =============================================================================
# Security Group for ECS Tasks
# =============================================================================

resource "aws_security_group" "fleet_ecs" {
  name        = "fleet-${var.environment}-ecs"
  description = "Fleet ECS Service Security Group"
  vpc_id      = var.vpc_id

  egress {
    description      = "Egress to all"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description     = "Ingress from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "TCP"
    security_groups = [module.alb_fleet.alb_security_group_id]
  }
}

# =============================================================================
# IAM Roles
# =============================================================================

data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["ecs.amazonaws.com", "ecs-tasks.amazonaws.com"]
      type        = "Service"
    }
  }
}

# Task Role - what the container can do
resource "aws_iam_role" "fleet_task" {
  name               = "fleet-${var.environment}-task-role"
  description        = "IAM role that Fleet application assumes when running in ECS"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
}

# Execution Role - what ECS agent can do (pull images, get secrets)
resource "aws_iam_role" "fleet_execution" {
  name               = "fleet-${var.environment}-execution-role"
  description        = "The execution role for Fleet in ECS"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
}

resource "aws_iam_role_policy_attachment" "fleet_execution_ecs" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.fleet_execution.name
}

# Execution role - secrets access
data "aws_iam_policy_document" "fleet_execution" {
  statement {
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      var.fleet_config.database.password_secret_arn,
      aws_secretsmanager_secret.fleet_server_private_key.arn,
      data.aws_secretsmanager_secret.fleet_license.arn,
    ]
  }
}

resource "aws_iam_role_policy" "fleet_execution" {
  name   = "fleet-${var.environment}-secrets"
  role   = aws_iam_role.fleet_execution.name
  policy = data.aws_iam_policy_document.fleet_execution.json
}

# Attach extra execution IAM policies (e.g., for CDN signing secrets)
resource "aws_iam_role_policy_attachment" "fleet_execution_extra" {
  for_each   = toset(var.fleet_config.extra_execution_iam_policies)
  policy_arn = each.value
  role       = aws_iam_role.fleet_execution.name
}

# Task role - CloudWatch metrics
data "aws_iam_policy_document" "fleet_task" {
  statement {
    effect    = "Allow"
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "fleet_task" {
  name   = "fleet-${var.environment}-cloudwatch"
  role   = aws_iam_role.fleet_task.name
  policy = data.aws_iam_policy_document.fleet_task.json
}

# Task role - SSM Parameter Store access
data "aws_kms_alias" "kms_ssm_key" {
  name = "alias/aws/ssm"
}

data "aws_iam_policy_document" "fleet_task_ssm" {
  statement {
    actions   = ["ssm:DescribeParameters"]
    resources = ["*"]
  }

  statement {
    actions   = ["ssm:GetParametersByPath"]
    resources = [format("arn:aws:ssm:*:*:parameter/fleet-%s/*", var.environment)]
  }

  statement {
    actions   = ["kms:ListKeys", "kms:ListAliases", "kms:Describe*", "kms:Decrypt"]
    resources = [data.aws_kms_alias.kms_ssm_key.target_key_arn]
  }
}

resource "aws_iam_role_policy" "fleet_task_ssm" {
  name   = "fleet-${var.environment}-ssm"
  role   = aws_iam_role.fleet_task.name
  policy = data.aws_iam_policy_document.fleet_task_ssm.json
}

# Task role - S3 software installers
data "aws_iam_policy_document" "software_installers" {
  count = var.fleet_config.software_installers.bucket_arn != null ? 1 : 0

  statement {
    actions = [
      "s3:GetObject*",
      "s3:PutObject*",
      "s3:ListBucket*",
      "s3:DeleteObject",
      "s3:CreateMultipartUpload",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
      "s3:GetBucketLocation"
    ]
    resources = [
      var.fleet_config.software_installers.bucket_arn,
      "${var.fleet_config.software_installers.bucket_arn}/*"
    ]
  }
}

resource "aws_iam_role_policy" "software_installers" {
  count = var.fleet_config.software_installers.bucket_arn != null ? 1 : 0

  name   = "fleet-${var.environment}-s3-software-installers"
  role   = aws_iam_role.fleet_task.name
  policy = data.aws_iam_policy_document.software_installers[0].json
}

# =============================================================================
# ECS Task Definition
# =============================================================================

resource "aws_ecs_task_definition" "fleet" {
  family                   = "fleet-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = coalesce(var.fleet_config.task_cpu, var.fleet_config.cpu)
  memory                   = coalesce(var.fleet_config.task_mem, var.fleet_config.mem)
  execution_role_arn       = aws_iam_role.fleet_execution.arn
  task_role_arn            = aws_iam_role.fleet_task.arn

  container_definitions = jsonencode(concat([
    {
      name        = "fleet"
      image       = local.fleet_effective_image
      cpu         = var.fleet_config.cpu
      memory      = var.fleet_config.mem
      essential   = true
      mountPoints = var.fleet_config.mount_points
      dependsOn   = var.fleet_config.depends_on
      volumesFrom = []

      command = ["sh", "-c", "fleet prepare db --no-prompt && fleet serve"]

      portMappings = [{
        containerPort = 8080
        protocol      = "tcp"
      }]

      repositoryCredentials = local.repository_credentials
      networkMode           = "awsvpc"

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.fleet.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = var.fleet_config.awslogs.prefix
        }
      }

      ulimits = [{
        name      = "nofile"
        softLimit = 999999
        hardLimit = 999999
      }]

      secrets = concat([
        {
          name      = "FLEET_MYSQL_PASSWORD"
          valueFrom = "${var.fleet_config.database.password_secret_arn}:password::"
        },
        {
          name      = "FLEET_MYSQL_READ_REPLICA_PASSWORD"
          valueFrom = "${var.fleet_config.database.password_secret_arn}:password::"
        },
        {
          name      = "FLEET_SERVER_PRIVATE_KEY"
          valueFrom = aws_secretsmanager_secret.fleet_server_private_key.arn
        }
      ], local.secrets)

      environment = concat([
        { name = "FLEET_MYSQL_USERNAME", value = var.fleet_config.database.user },
        { name = "FLEET_MYSQL_DATABASE", value = var.fleet_config.database.database },
        { name = "FLEET_MYSQL_ADDRESS", value = var.fleet_config.database.address },
        { name = "FLEET_MYSQL_READ_REPLICA_USERNAME", value = var.fleet_config.database.user },
        { name = "FLEET_MYSQL_READ_REPLICA_DATABASE", value = var.fleet_config.database.database },
        {
          name  = "FLEET_MYSQL_READ_REPLICA_ADDRESS"
          value = coalesce(var.fleet_config.database.rr_address, var.fleet_config.database.address)
        },
        { name = "FLEET_REDIS_ADDRESS", value = var.fleet_config.redis.address },
        { name = "FLEET_REDIS_USE_TLS", value = tostring(var.fleet_config.redis.use_tls) },
        { name = "FLEET_SERVER_TLS", value = "false" },
        { name = "FLEET_S3_SOFTWARE_INSTALLERS_BUCKET", value = var.fleet_config.software_installers.bucket_name },
        { name = "FLEET_S3_SOFTWARE_INSTALLERS_PREFIX", value = var.fleet_config.software_installers.s3_object_prefix },
      ], local.environment)
    }
  ], var.fleet_config.sidecars))

  dynamic "volume" {
    for_each = var.fleet_config.volumes
    content {
      name      = volume.value.name
      host_path = lookup(volume.value, "host_path", null)

      dynamic "efs_volume_configuration" {
        for_each = lookup(volume.value, "efs_volume_configuration", [])
        content {
          file_system_id = lookup(efs_volume_configuration.value, "file_system_id", null)
          root_directory = lookup(efs_volume_configuration.value, "root_directory", null)
        }
      }
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# =============================================================================
# ECS Service
# =============================================================================

resource "aws_ecs_service" "fleet" {
  name                               = "fleet-${var.environment}"
  cluster                            = data.aws_ecs_cluster.main.arn
  task_definition                    = aws_ecs_task_definition.fleet.arn
  desired_count                      = var.tasks_desired_count
  launch_type                        = "FARGATE"
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  health_check_grace_period_seconds  = 30

  network_configuration {
    subnets         = var.ecs_subnets
    security_groups = [aws_security_group.fleet_ecs.id]
  }

  load_balancer {
    target_group_arn = module.alb_fleet.alb_target_group_id
    container_name   = "fleet"
    container_port   = 8080
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}

# =============================================================================
# Autoscaling
# =============================================================================

resource "aws_appautoscaling_target" "fleet" {
  max_capacity       = var.fleet_config.autoscaling.max_capacity
  min_capacity       = var.fleet_config.autoscaling.min_capacity
  resource_id        = "service/${data.aws_ecs_cluster.main.cluster_name}/${aws_ecs_service.fleet.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "fleet_memory" {
  name               = "fleet-${var.environment}-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.fleet.resource_id
  scalable_dimension = aws_appautoscaling_target.fleet.scalable_dimension
  service_namespace  = aws_appautoscaling_target.fleet.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = var.fleet_config.autoscaling.memory_tracking_target_value
  }
}

resource "aws_appautoscaling_policy" "fleet_cpu" {
  name               = "fleet-${var.environment}-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.fleet.resource_id
  scalable_dimension = aws_appautoscaling_target.fleet.scalable_dimension
  service_namespace  = aws_appautoscaling_target.fleet.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = var.fleet_config.autoscaling.cpu_tracking_target_value
  }
}
