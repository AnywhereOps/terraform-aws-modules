# These data sources provide information about the environment this
# terraform is running in -- it's how we can know which account, region,
# and partition (ie, commercial AWS vs GovCloud) we're in.

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_secretsmanager_secret" "fleet_license" {
  name = "fleet-license"
}

# Fleet container definition - copied from byo-ecs/main.tf:1-22, 65-161
locals {
  environment = [for k, v in var.fleet_config.extra_environment_variables : {
    name  = k
    value = v
  }]
  license_secret = [{
    name      = "FLEET_LICENSE_KEY"
    valueFrom = data.aws_secretsmanager_secret.fleet_license.arn
  }]
  secrets = concat(local.license_secret, [for k, v in var.fleet_config.extra_secrets : {
    name      = k
    valueFrom = v
  }])
  repository_credentials = var.fleet_config.repository_credentials != "" ? {
    credentialsParameter = var.fleet_config.repository_credentials
  } : null
}


# This creates a certificate via AWS Certificate Manager that we can
# use with the load balancer for our application, and the DNS record
# that we use to validate that we actually own the domain.

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

# Every application that we want to expose to the internet somehow
# is going to need some sort of load balancer. This lets us abstract
# the interface between the user and the containers running the actual
# application.
#
# In this case, we're using a Application Load Balancer (ALB), which
# is a layer 7 load balancer, which means it operates on HTTP; AWS also
# offers Network Load Balancers (NLB) which operate on layer 4, which
# means it operates on TCP. NLBs are used less commonly now, but are
# used in cases where the traffic is not HTTP or where the container
# needs to terminate SSL, such as when we're using client-cert auth.

module "alb_fleet" {
  source  = "trussworks/alb-web-containers/aws"
  version = "~> 10.0.0"

  name           = "fleet"
  environment    = var.environment
  logs_s3_bucket = var.alb_logs_bucket
  logs_s3_prefix = "alb"

  # The SSL policy here describes which protocols and ciphers can be used
  # to connect to the ALB. You can see a full description of these policies
  # here:
  # https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies
  alb_ssl_policy              = "ELBSecurityPolicy-TLS-1-2-2017-01"
  alb_default_certificate_arn = aws_acm_certificate_validation.fleet.certificate_arn
  alb_certificate_arns        = []
  alb_vpc_id                  = var.vpc_id
  alb_subnet_ids              = var.alb_subnets

  # Note that for the container protocol here we're specifying HTTP,
  # which means the connection between the ALB and the container will
  # be unencrypted. This is done here for simplicity's sake; in a real
  # world implementation, we would make this HTTPS and give the container
  # a self-signed certificate so that the connection between the
  # containers and the ALB would *also* be encrypted.
  container_protocol = "HTTP"
  container_port     = var.container_port

  # Fleet's health endpoint
  health_check_path     = var.alb_health_check_path
  health_check_interval = var.alb_health_check_interval
  health_check_timeout  = var.alb_health_check_timeout

  target_group_name = format("fleet-%s-%s", var.environment, var.container_port)

  allow_public_https = true
  allow_public_http  = true
}

# The ALB module will generate an ALB with a patterned DNS name -- something
# like "fleet-prod-12345678.us-west-2.elb.amazonaws.com". This name will
# also get regenerated if we rebuild the ALB for some reason, so if we can,
# we should make a DNS alias for this ALB that is something more intelligible.
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

# We want to use a KMS key to encrypt our Cloudwatch logs for this
# service; this keeps the logs encrypted at rest on disk. As a rule, we
# always want to use encryption like this where we can.
#
# This sets up a policy that lets Cloudwatch logs actually use our KMS
# keys and then creates a key to use for encrypting these logs.

data "aws_iam_policy_document" "cloudwatch_logs_allow_kms" {
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
      ]
    }

    actions = [
      "kms:*",
    ]
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

  policy = data.aws_iam_policy_document.cloudwatch_logs_allow_kms.json
}

# Fleet server private key - used for session encryption
# This is auto-generated and stored in Secrets Manager
# This stores the private key in state. We will move to Trussworks patterns in the future
# These patterns are commented out for now to avoid breaking changes.
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

# Reference the shared ECS cluster from stacks/ecs-cluster
# Fleet uses the public Docker Hub image (fleetdm/fleet), so no ECR needed
data "aws_ecs_cluster" "main" {
  cluster_name = var.ecs_cluster_name
}

# This will be used when we build fleet images ourselves
# This data source pulls in the ECR repo for this application so we can
# use the docker containers stored there. This is created with the
# aws-example-ecr-repo in the overall namespace.
# data "aws_ecr_repository" "app_my_webapp" {
#   name = "app-my-webapp"
# }

# This is where we're actually defining the Fargate service for this
# application. The Truss module will seed the task definition for this
# service with a placeholder helloworld application; we use the CI/CD
# pipeline to replace that later with the real task definition.

module "ecs_service_fleet" {
  source  = "trussworks/ecs-service/aws"
  version = "~> 8.0.0"

  name                  = "fleet"
  environment           = var.environment
  target_container_name = "fleet"

  logs_cloudwatch_retention = var.cloudwatch_logs_retention_days
  logs_cloudwatch_group     = format("ecs-tasks-fleet-%s", var.environment)
  # Fleet uses Docker Hub (fleetdm/fleet), not ECR. Default allows any registry.
  ecr_repo_arns = ["*"]
  # ecr_repo_arns                 = [data.aws_ecr_repository.app_my_webapp.arn] # For when we build fleet image ourselves
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

  # ALB integration
  associate_alb      = true
  alb_security_group = module.alb_fleet.alb_security_group_id

  lb_target_groups = [
    {
      container_port              = var.container_port
      container_health_check_port = var.container_port
      lb_target_group_arn         = module.alb_fleet.alb_target_group_id
    }
  ]
  kms_key_id = aws_kms_key.fleet_logs.arn

  container_definitions = jsonencode(
    concat([
      {
        name        = "fleet"
        image       = var.fleet_config.image
        cpu         = var.fleet_config.cpu
        memory      = var.fleet_config.mem
        mountPoints = var.fleet_config.mount_points
        dependsOn   = var.fleet_config.depends_on
        volumesFrom = []
        essential   = true
        command     = ["sh", "-c", "fleet prepare db --no-prompt && fleet serve"]
        portMappings = [
          {
            # This port is the same that the contained application also uses
            containerPort = 8080
            protocol      = "tcp"
          }
        ]
        repositoryCredentials = local.repository_credentials
        networkMode           = "awsvpc"
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            # Trussworks module creates the log group via logs_cloudwatch_group
            awslogs-group         = format("ecs-tasks-fleet-%s", var.environment)
            awslogs-region        = data.aws_region.current.name
            awslogs-stream-prefix = var.fleet_config.awslogs.prefix
          }
        },
        ulimits = [
          {
            name      = "nofile"
            softLimit = 999999
            hardLimit = 999999
          }
        ],
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
          {
            name  = "FLEET_MYSQL_USERNAME"
            value = var.fleet_config.database.user
          },
          {
            name  = "FLEET_MYSQL_DATABASE"
            value = var.fleet_config.database.database
          },
          {
            name  = "FLEET_MYSQL_ADDRESS"
            value = var.fleet_config.database.address
          },
          {
            name  = "FLEET_MYSQL_READ_REPLICA_USERNAME"
            value = var.fleet_config.database.user
          },
          {
            name  = "FLEET_MYSQL_READ_REPLICA_DATABASE"
            value = var.fleet_config.database.database
          },
          {
            name  = "FLEET_MYSQL_READ_REPLICA_ADDRESS"
            value = var.fleet_config.database.rr_address == null ? var.fleet_config.database.address : var.fleet_config.database.rr_address
          },
          {
            name  = "FLEET_REDIS_ADDRESS"
            value = var.fleet_config.redis.address
          },
          {
            name  = "FLEET_REDIS_USE_TLS"
            value = tostring(var.fleet_config.redis.use_tls)
          },
          {
            name  = "FLEET_SERVER_TLS"
            value = "false"
          },
          {
            # Bucket provided by shared S3/CloudFront module (with Munki)
            name  = "FLEET_S3_SOFTWARE_INSTALLERS_BUCKET"
            value = var.fleet_config.software_installers.bucket_name
          },
          {
            name  = "FLEET_S3_SOFTWARE_INSTALLERS_PREFIX"
            value = var.fleet_config.software_installers.s3_object_prefix
          },
        ], local.environment)
      }
  ], var.fleet_config.sidecars))
}

# KMS Key used by AWS Parameter Store
data "aws_kms_alias" "kms_ssm_key" {
  name = "alias/aws/ssm"
}

# This policy for the ECS task role lets it access the AWS Parameter
# Store. This isn't strictly necessary, but it's a common pattern at
# Truss to store environment variables for applications in the Parameter
# Store and retrieve them at runtime with chamber, so this is something
# we'll see often.

data "aws_iam_policy_document" "fleet_task_role" {

  statement {
    actions = [
      "ssm:DescribeParameters"
    ]
    resources = [
      "*"
    ]
  }

  # Allow access to the environment specific app secrets
  statement {
    actions = [
      "ssm:GetParametersByPath"
    ]
    resources = [
      format("arn:aws:ssm:*:*:parameter/fleet-%s/*", var.environment)
    ]
  }

  # Allow decryption of Parameter Store values
  statement {
    actions = [
      "kms:ListKeys",
      "kms:ListAliases",
      "kms:Describe*",
      "kms:Decrypt",
    ]

    resources = [
      "${data.aws_kms_alias.kms_ssm_key.target_key_arn}"
    ]
  }
}

resource "aws_iam_role_policy" "fleet_task_role" {
  name   = format("%s-policy", module.ecs_service_fleet.task_role_name)
  role   = module.ecs_service_fleet.task_role_name
  policy = data.aws_iam_policy_document.fleet_task_role.json
}

# Execution role policy - allows ECS to pull secrets before container starts
data "aws_iam_policy_document" "fleet_execution_role" {
  statement {
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      aws_secretsmanager_secret.fleet_server_private_key.arn,
      var.fleet_config.database.password_secret_arn,
      data.aws_secretsmanager_secret.fleet_license.arn,
    ]
  }
}

resource "aws_iam_role_policy" "fleet_execution_role" {
  name   = format("%s-secrets", module.ecs_service_fleet.task_execution_role_name)
  role   = module.ecs_service_fleet.task_execution_role_name
  policy = data.aws_iam_policy_document.fleet_execution_role.json
}

# locals {
#   software_installers_kms_policy = var.fleet_config.software_installers.create_kms_key == true ? [{
#     sid = "AllowSoftwareInstallersKMSAccess"
#     actions = [
#       "kms:ReEncrypt*",
#       "kms:GenerateDataKey*",
#       "kms:Encrypt*",
#       "kms:Describe*",
#       "kms:Decrypt*"
#     ]
#     resources = [aws_kms_key.software_installers[0].arn]
#     effect    = "Allow"
#   }] : []
# }

# # Task role policy - allows Fleet to publish CloudWatch metrics at runtime
# resource "aws_iam_role_policy" "fleet_task_cloudwatch" {
#   name = "fleet-cloudwatch-metrics"
#   role = module.ecs_service_fleet.task_role_name

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect   = "Allow"
#       Action   = ["cloudwatch:PutMetricData"]
#       Resource = ["*"]
#     }]
#   })
# }

# # Task role policy - S3 software installers (TODO: uncomment when shared S3 module is ready)
# data "aws_iam_policy_document" "software_installers" {
#   count = var.fleet_config.software_installers.create_bucket == true ? 1 : 0
#   statement {
#     actions = [
#       "s3:GetObject*",
#       "s3:PutObject*",
#       "s3:ListBucket*",
#       "s3:ListMultipartUploadParts*",
#       "s3:DeleteObject",
#       "s3:CreateMultipartUpload",
#       "s3:AbortMultipartUpload",
#       "s3:ListMultipartUploadParts",
#       "s3:GetBucketLocation"
#     ]
#     resources = [aws_s3_bucket.software_installers[0].arn, "${aws_s3_bucket.software_installers[0].arn}/*"]
#   }
#   dynamic "statement" {
#     for_each = local.software_installers_kms_policy
#     content {
#       sid       = try(statement.value.sid, "")
#       actions   = try(statement.value.actions, [])
#       resources = try(statement.value.resources, [])
#       effect    = try(statement.value.effect, null)
#       dynamic "principals" {
#         for_each = try(statement.value.principals, [])
#         content {
#           type        = principals.value.type
#           identifiers = principals.value.identifiers
#         }
#       }
#       dynamic "condition" {
#         for_each = try(statement.value.conditions, [])
#         content {
#           test     = condition.value.test
#           variable = condition.value.variable
#           values   = condition.value.values
#         }
#       }
#     }
#   }
# }

# resource "aws_iam_policy" "software_installers" {
#   count  = var.fleet_config.software_installers.create_bucket == true ? 1 : 0
#   policy = data.aws_iam_policy_document.software_installers[count.index].json
# }
