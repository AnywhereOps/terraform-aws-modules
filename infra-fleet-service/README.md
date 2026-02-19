This module creates the set of resources necessary to stand up a stack
for the `my-webapp` application, including:

* ALB with Route53 DNS record and ACM certificate
* ECS cluster
* ECS service
* RDS instance

```hcl
module "app_my_webapp_dev" {
  source = "../../modules/aws-example-webapp

  alb_logs_bucket = var.logging_bucket
  alb_subnets     = module.my_webapp_vpc.public_subnets

  db_subnet_group_name = module.my_webapp_vpc.vpc_name
  db_subnets           = module.my_webapp_vpc.database_subnets

  dns_zone_id = data.aws_route53_zone.dev_zone.zone_id
  domain_name = "my-webapp.dev.example.com"

  ecs_subnets = module.my_webapp_vpc.private_subnets
  environment = "dev"

  vpc_id = module.my_webapp_vpc.vpc_id
}

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| aws | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| alb\_my\_webapp | trussworks/alb-web-containers/aws | ~> 7.0.0 |
| ecs\_service\_my\_webapp | trussworks/ecs-service/aws | ~> 6.6.0 |
| my\_webapp\_db | terraform-aws-modules/rds/aws | ~> 5.0 |

## Resources

| Name | Type |
|------|------|
| [aws_acm_certificate.acm_my_webapp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_ecs_cluster.app_my_webapp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_iam_role_policy.task_role_policy_my_webapp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_kms_key.ecs_logs_my_webapp_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_route53_record.acm_my_webapp_validation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.my_webapp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_security_group.rds_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.rds_allow_ecs_app_inbound](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_ssm_parameter.database_host](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.database_name](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.database_user](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_ecr_repository.app_my_webapp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ecr_repository) | data source |
| [aws_iam_policy_document.cloudwatch_logs_allow_kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.task_role_policy_doc_my_webapp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_kms_alias.kms_ssm_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_alias) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_ssm_parameter.database_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| alb\_health\_check\_interval | Interval for ALB health check (in seconds) | `number` | `30` | no |
| alb\_health\_check\_path | Path for ALB health check | `string` | `"/health"` | no |
| alb\_health\_check\_timeout | Timeout for ALB health check (in seconds) | `number` | `5` | no |
| alb\_logs\_bucket | S3 bucket for ALB logs | `string` | n/a | yes |
| alb\_subnets | Subnets for ALB | `list(string)` | n/a | yes |
| container\_port | Port for container listener | `number` | `8080` | no |
| db\_allocated\_storage | Allocated storage for RDS instance (in GB) | `number` | `20` | no |
| db\_backup\_retention | RDS backup retention (in days) | `number` | `7` | no |
| db\_instance\_class | Instance class for RDS instance | `string` | `"db.t3.small"` | no |
| db\_multi\_az | Multi AZ setting for RDS | `bool` | `false` | no |
| db\_name | Name for database on RDS instance | `string` | `"my_webapp"` | no |
| db\_subnet\_group\_name | DB subnet group name | `string` | n/a | yes |
| db\_subnets | List of DB subnets | `list(string)` | n/a | yes |
| db\_user | User for accessing RDS instance | `string` | `"master"` | no |
| dns\_zone\_id | Zone ID for DNS | `string` | n/a | yes |
| domain\_name | Outward facing FQDN for service | `string` | n/a | yes |
| ecs\_subnets | Subnets for ECS service | `list(string)` | n/a | yes |
| environment | Environment | `string` | n/a | yes |
| final\_snapshot\_identifier | Final RDS snapshot identifier | `string` | `""` | no |
| pg\_family | DB parameter family for RDS instance | `string` | `"postgres12"` | no |
| pg\_version | PostgreSQL version for the RDS instance | `string` | `"12.2"` | no |
| tasks\_desired\_count | Number of ECS tasks to run | `number` | `1` | no |
| vpc\_id | VPC ID | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_alb_fleet"></a> [alb\_fleet](#module\_alb\_fleet) | trussworks/alb-web-containers/aws | ~> 10.0.0 |
| <a name="module_ecs_service_fleet"></a> [ecs\_service\_fleet](#module\_ecs\_service\_fleet) | trussworks/ecs-service/aws | ~> 8.0.0 |

## Resources

| Name | Type |
|------|------|
| [aws_acm_certificate.fleet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_iam_role_policy.fleet_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.fleet_task_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_kms_key.fleet_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_route53_record.fleet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.fleet_acm_validation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_secretsmanager_secret.fleet_server_private_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.fleet_server_private_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [random_password.fleet_server_private_key](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_ecs_cluster.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ecs_cluster) | data source |
| [aws_iam_policy_document.cloudwatch_logs_allow_kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.fleet_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.fleet_task_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_kms_alias.kms_ssm_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_alias) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alb_logs_bucket"></a> [alb\_logs\_bucket](#input\_alb\_logs\_bucket) | S3 bucket for ALB logs | `string` | n/a | yes |
| <a name="input_alb_subnets"></a> [alb\_subnets](#input\_alb\_subnets) | Subnets for ALB | `list(string)` | n/a | yes |
| <a name="input_db_subnet_group_name"></a> [db\_subnet\_group\_name](#input\_db\_subnet\_group\_name) | DB subnet group name | `string` | n/a | yes |
| <a name="input_db_subnets"></a> [db\_subnets](#input\_db\_subnets) | List of DB subnets | `list(string)` | n/a | yes |
| <a name="input_dns_zone_id"></a> [dns\_zone\_id](#input\_dns\_zone\_id) | Zone ID for DNS | `string` | n/a | yes |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Outward facing FQDN for service | `string` | n/a | yes |
| <a name="input_ecs_cluster_name"></a> [ecs\_cluster\_name](#input\_ecs\_cluster\_name) | Name of the ECS cluster (from stacks/ecs-cluster) | `string` | n/a | yes |
| <a name="input_ecs_subnets"></a> [ecs\_subnets](#input\_ecs\_subnets) | Subnets for ECS service | `list(string)` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID | `string` | n/a | yes |
| <a name="input_alb_health_check_interval"></a> [alb\_health\_check\_interval](#input\_alb\_health\_check\_interval) | Interval for ALB health check (in seconds) | `number` | `30` | no |
| <a name="input_alb_health_check_path"></a> [alb\_health\_check\_path](#input\_alb\_health\_check\_path) | Path for ALB health check | `string` | `"/healthz"` | no |
| <a name="input_alb_health_check_timeout"></a> [alb\_health\_check\_timeout](#input\_alb\_health\_check\_timeout) | Timeout for ALB health check (in seconds) | `number` | `5` | no |
| <a name="input_cloudwatch_logs_retention_days"></a> [cloudwatch\_logs\_retention\_days](#input\_cloudwatch\_logs\_retention\_days) | CloudWatch Logs retention in days | `number` | `90` | no |
| <a name="input_container_port"></a> [container\_port](#input\_container\_port) | Port Fleet container listens on (Fleet uses 8080 by default) | `number` | `8080` | no |
| <a name="input_db_allocated_storage"></a> [db\_allocated\_storage](#input\_db\_allocated\_storage) | Allocated storage for RDS instance (in GB) | `number` | `20` | no |
| <a name="input_db_backup_retention"></a> [db\_backup\_retention](#input\_db\_backup\_retention) | RDS backup retention (in days) | `number` | `7` | no |
| <a name="input_db_instance_class"></a> [db\_instance\_class](#input\_db\_instance\_class) | Instance class for RDS instance | `string` | `"db.t3.small"` | no |
| <a name="input_db_multi_az"></a> [db\_multi\_az](#input\_db\_multi\_az) | Multi AZ setting for RDS | `bool` | `false` | no |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | Name for database on RDS instance | `string` | `"my_webapp"` | no |
| <a name="input_db_user"></a> [db\_user](#input\_db\_user) | User for accessing RDS instance | `string` | `"master"` | no |
| <a name="input_final_snapshot_identifier"></a> [final\_snapshot\_identifier](#input\_final\_snapshot\_identifier) | Final RDS snapshot identifier | `string` | `""` | no |
| <a name="input_fleet_config"></a> [fleet\_config](#input\_fleet\_config) | The configuration object for Fleet itself. Fields that default to null will have their respective resources created if not specified. | <pre>object({<br/>    task_mem                     = optional(number, null)<br/>    task_cpu                     = optional(number, null)<br/>    mem                          = optional(number, 4096)<br/>    cpu                          = optional(number, 512)<br/>    pid_mode                     = optional(string, null)<br/>    image                        = optional(string, "fleetdm/fleet:v4.78.0")<br/>    family                       = optional(string, "fleet")<br/>    sidecars                     = optional(list(any), [])<br/>    depends_on                   = optional(list(any), [])<br/>    mount_points                 = optional(list(any), [])<br/>    volumes                      = optional(list(any), [])<br/>    extra_environment_variables  = optional(map(string), {})<br/>    extra_iam_policies           = optional(list(string), [])<br/>    extra_execution_iam_policies = optional(list(string), [])<br/>    extra_secrets                = optional(map(string), {})<br/>    security_group_name          = optional(string, "fleet")<br/>    iam_role_arn                 = optional(string, null)<br/>    repository_credentials       = optional(string, "")<br/>    private_key_secret_name      = optional(string, "fleet-server-private-key")<br/>    service = optional(object({<br/>      name = optional(string, "fleet")<br/>      }), {<br/>      name = "fleet"<br/>    })<br/>    database = object({<br/>      password_secret_arn = string<br/>      user                = string<br/>      database            = string<br/>      address             = string<br/>      rr_address          = optional(string, null)<br/>    })<br/>    redis = object({<br/>      address = string<br/>      use_tls = optional(bool, true)<br/>    })<br/>    awslogs = optional(object({<br/>      name      = optional(string, null)<br/>      region    = optional(string, null)<br/>      create    = optional(bool, true)<br/>      prefix    = optional(string, "fleet")<br/>      retention = optional(number, 5)<br/>      }), {<br/>      name      = null<br/>      region    = null<br/>      prefix    = "fleet"<br/>      retention = 5<br/>    })<br/>    loadbalancer = object({<br/>      arn = string<br/>    })<br/>    extra_load_balancers = optional(list(any), [])<br/>    networking = object({<br/>      subnets         = optional(list(string), null)<br/>      security_groups = optional(list(string), null)<br/>      ingress_sources = object({<br/>        cidr_blocks      = optional(list(string), [])<br/>        ipv6_cidr_blocks = optional(list(string), [])<br/>        security_groups  = optional(list(string), [])<br/>        prefix_list_ids  = optional(list(string), [])<br/>      })<br/>    })<br/>    autoscaling = optional(object({<br/>      max_capacity                 = optional(number, 5)<br/>      min_capacity                 = optional(number, 1)<br/>      memory_tracking_target_value = optional(number, 80)<br/>      cpu_tracking_target_value    = optional(number, 80)<br/>      }), {<br/>      max_capacity                 = 5<br/>      min_capacity                 = 1<br/>      memory_tracking_target_value = 80<br/>      cpu_tracking_target_value    = 80<br/>    })<br/>    iam = optional(object({<br/>      role = optional(object({<br/>        name        = optional(string, "fleet-role")<br/>        policy_name = optional(string, "fleet-iam-policy")<br/>        }), {<br/>        name        = "fleet-role"<br/>        policy_name = "fleet-iam-policy"<br/>      })<br/>      execution = optional(object({<br/>        name        = optional(string, "fleet-execution-role")<br/>        policy_name = optional(string, "fleet-execution-role")<br/>        }), {<br/>        name        = "fleet-execution-role"<br/>        policy_name = "fleet-iam-policy-execution"<br/>      })<br/>      }), {<br/>      name = "fleetdm-execution-role"<br/>    })<br/>    software_installers = optional(object({<br/>      create_bucket                      = optional(bool, true)<br/>      bucket_name                        = optional(string, null)<br/>      bucket_prefix                      = optional(string, "fleet-software-installers-")<br/>      s3_object_prefix                   = optional(string, "")<br/>      enable_bucket_versioning           = optional(bool, false)<br/>      expire_noncurrent_versions         = optional(bool, true)<br/>      noncurrent_version_expiration_days = optional(number, 30)<br/>      create_kms_key                     = optional(bool, false)<br/>      kms_alias                          = optional(string, "fleet-software-installers")<br/>      tags                               = optional(map(string), {})<br/>      }), {<br/>      create_bucket                      = true<br/>      bucket_name                        = null<br/>      bucket_prefix                      = "fleet-software-installers-"<br/>      s3_object_prefix                   = ""<br/>      enable_bucket_versioning           = false<br/>      expire_noncurrent_versions         = true<br/>      noncurrent_version_expiration_days = 30<br/>      create_kms_key                     = false<br/>      kms_alias                          = "fleet-software-installers"<br/>      tags                               = {}<br/>    })<br/>  })</pre> | <pre>{<br/>  "autoscaling": {<br/>    "cpu_tracking_target_value": 80,<br/>    "max_capacity": 5,<br/>    "memory_tracking_target_value": 80,<br/>    "min_capacity": 1<br/>  },<br/>  "awslogs": {<br/>    "create": true,<br/>    "name": null,<br/>    "prefix": "fleet",<br/>    "region": null,<br/>    "retention": 5<br/>  },<br/>  "cpu": 256,<br/>  "database": {<br/>    "address": null,<br/>    "database": null,<br/>    "password_secret_arn": null,<br/>    "rr_address": null,<br/>    "user": null<br/>  },<br/>  "depends_on": [],<br/>  "extra_environment_variables": {},<br/>  "extra_execution_iam_policies": [],<br/>  "extra_iam_policies": [],<br/>  "extra_load_balacners": [],<br/>  "extra_secrets": {},<br/>  "family": "fleet",<br/>  "iam": {<br/>    "execution": {<br/>      "name": "fleet-execution-role",<br/>      "policy_name": "fleet-iam-policy-execution"<br/>    },<br/>    "role": {<br/>      "name": "fleet-role",<br/>      "policy_name": "fleet-iam-policy"<br/>    }<br/>  },<br/>  "iam_role_arn": null,<br/>  "image": "fleetdm/fleet:v4.78.0",<br/>  "loadbalancer": {<br/>    "arn": null<br/>  },<br/>  "mem": 512,<br/>  "mount_points": [],<br/>  "networking": {<br/>    "ingress_sources": {<br/>      "cidr_blocks": [],<br/>      "ipv6_cidr_blocks": [],<br/>      "prefix_list_ids": [],<br/>      "security_groups": []<br/>    },<br/>    "security_groups": null,<br/>    "subnets": null<br/>  },<br/>  "pid_mode": null,<br/>  "private_key_secret_name": "fleet-server-private-key",<br/>  "redis": {<br/>    "address": null,<br/>    "use_tls": true<br/>  },<br/>  "repository_credentials": "",<br/>  "security_group_name": "fleet",<br/>  "service": {<br/>    "name": "fleet"<br/>  },<br/>  "sidecars": [],<br/>  "software_installers": {<br/>    "bucket_name": null,<br/>    "bucket_prefix": "fleet-software-installers-",<br/>    "create_bucket": true,<br/>    "s3_object_prefix": ""<br/>  },<br/>  "task_cpu": null,<br/>  "task_mem": null,<br/>  "volumes": []<br/>}</pre> | no |
| <a name="input_tasks_desired_count"></a> [tasks\_desired\_count](#input\_tasks\_desired\_count) | Number of ECS tasks to run | `number` | `1` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alb_arn"></a> [alb\_arn](#output\_alb\_arn) | ARN of the ALB |
| <a name="output_alb_arn_suffix"></a> [alb\_arn\_suffix](#output\_alb\_arn\_suffix) | ARN suffix of the ALB (used for CloudWatch metrics) |
| <a name="output_alb_dns_name"></a> [alb\_dns\_name](#output\_alb\_dns\_name) | DNS name of the ALB |
| <a name="output_alb_listener_arn"></a> [alb\_listener\_arn](#output\_alb\_listener\_arn) | ARN of the HTTPS listener (used for adding listener rules) |
| <a name="output_alb_security_group_id"></a> [alb\_security\_group\_id](#output\_alb\_security\_group\_id) | Security group ID of the ALB (used by ECS service for ingress rules) |
| <a name="output_alb_target_group_arn"></a> [alb\_target\_group\_arn](#output\_alb\_target\_group\_arn) | ARN of the ALB target group (used by ECS service to register tasks) |
<!-- END_TF_DOCS -->