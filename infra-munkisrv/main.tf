# -----------------------------------------------------------------------------
# Data sources
# -----------------------------------------------------------------------------

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

# ECR repository (created by terraform-github-live/munkisrv)
data "aws_ecr_repository" "munkisrv" {
  name = var.ecr_repo_name
}

# ECS cluster (created by infra-ecs-cluster)
data "aws_ecs_cluster" "main" {
  cluster_name = var.ecs_cluster_name
}

# -----------------------------------------------------------------------------
# ACM Certificate
# -----------------------------------------------------------------------------

resource "aws_acm_certificate" "munkisrv" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "munkisrv_acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.munkisrv.domain_validation_options : dvo.domain_name => {
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

resource "aws_acm_certificate_validation" "munkisrv" {
  certificate_arn         = aws_acm_certificate.munkisrv.arn
  validation_record_fqdns = [for record in aws_route53_record.munkisrv_acm_validation : record.fqdn]
}

# -----------------------------------------------------------------------------
# ALB
# -----------------------------------------------------------------------------

module "alb_munkisrv" {
  source  = "trussworks/alb-web-containers/aws"
  version = "~> 10.0.0"

  name           = "munkisrv"
  environment    = var.environment
  logs_s3_bucket = var.alb_logs_bucket
  logs_s3_prefix = "alb"

  alb_ssl_policy              = "ELBSecurityPolicy-TLS-1-2-2017-01"
  alb_default_certificate_arn = aws_acm_certificate_validation.munkisrv.certificate_arn
  alb_certificate_arns        = []
  alb_vpc_id                  = var.vpc_id
  alb_subnet_ids              = var.alb_subnets

  container_protocol = "HTTP"
  container_port     = var.container_port

  health_check_path     = "/healthz"
  health_check_interval = 30
  health_check_timeout  = 5

  target_group_name = format("munkisrv-%s-%s", var.environment, var.container_port)

  allow_public_https = true
  allow_public_http  = true
}

# Route53 A record for ALB
resource "aws_route53_record" "munkisrv" {
  name    = var.domain_name
  zone_id = var.dns_zone_id
  type    = "A"

  alias {
    name                   = module.alb_munkisrv.alb_dns_name
    zone_id                = module.alb_munkisrv.alb_zone_id
    evaluate_target_health = false
  }
}

# -----------------------------------------------------------------------------
# KMS for CloudWatch Logs
# -----------------------------------------------------------------------------

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

resource "aws_kms_key" "munkisrv_logs" {
  description         = "Key for munkisrv ECS log encryption"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.cloudwatch_logs_allow_kms.json
}

# -----------------------------------------------------------------------------
# ECS Service
# -----------------------------------------------------------------------------

locals {
  image = "${data.aws_ecr_repository.munkisrv.repository_url}:${var.image_tag}"
}

module "ecs_service_munkisrv" {
  source  = "trussworks/ecs-service/aws"
  version = "~> 8.0.0"

  name                  = "munkisrv"
  environment           = var.environment
  target_container_name = "munkisrv"

  logs_cloudwatch_retention = var.cloudwatch_logs_retention_days
  logs_cloudwatch_group     = format("ecs-tasks-munkisrv-%s", var.environment)

  ecr_repo_arns = [data.aws_ecr_repository.munkisrv.arn]

  ecs_cluster = {
    arn  = data.aws_ecs_cluster.main.arn
    name = data.aws_ecs_cluster.main.cluster_name
  }

  ecs_subnet_ids                = var.ecs_subnets
  ecs_use_fargate               = true
  ecs_vpc_id                    = var.vpc_id
  tasks_desired_count           = var.tasks_desired_count
  tasks_minimum_healthy_percent = 100
  tasks_maximum_percent         = 200

  associate_alb      = true
  alb_security_group = module.alb_munkisrv.alb_security_group_id

  lb_target_groups = [
    {
      container_port              = var.container_port
      container_health_check_port = var.container_port
      lb_target_group_arn         = module.alb_munkisrv.alb_target_group_id
    }
  ]

  kms_key_id = aws_kms_key.munkisrv_logs.arn

  container_definitions = jsonencode([
    {
      name        = "munkisrv"
      image       = local.image
      cpu         = var.cpu
      memory      = var.memory
      mountPoints = []
      volumesFrom = []
      essential   = true
      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]
      networkMode = "awsvpc"
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = format("ecs-tasks-munkisrv-%s", var.environment)
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "munkisrv"
        }
      }
      environment = [
        {
          name  = "ENV_CLOUDFRONT_URL"
          value = var.cloudfront_url
        },
        {
          name  = "ENV_SERVER_PORT"
          value = ":${var.container_port}"
        }
      ]
      secrets = [
        {
          name      = "ENV_CLOUDFRONT_KEY_ID"
          valueFrom = "${var.signing_secret_arn}:cloudfront_public_key_id::"
        },
        {
          name      = "ENV_CLOUDFRONT_PRIVATE_KEY"
          valueFrom = "${var.signing_secret_arn}:private_key::"
        }
      ]
    }
  ])
}

# -----------------------------------------------------------------------------
# IAM - Execution Role (pull secrets before container starts)
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "munkisrv_execution_role" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [var.signing_secret_arn]
  }

  # KMS decrypt permission for secrets encrypted with custom KMS key
  statement {
    actions   = ["kms:Decrypt"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["secretsmanager.${data.aws_region.current.name}.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "munkisrv_execution_role" {
  name   = format("%s-secrets", module.ecs_service_munkisrv.task_execution_role_name)
  role   = module.ecs_service_munkisrv.task_execution_role_name
  policy = data.aws_iam_policy_document.munkisrv_execution_role.json
}
