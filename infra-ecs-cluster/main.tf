# These data sources provide information about the environment this
# terraform is running in -- it's how we can know which account, region,
# and partition (ie, commercial AWS vs GovCloud) we're in.

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_default_tags" "provider" {}

locals {
  tags = data.aws_default_tags.provider.tags
}

# Shared ECS Cluster
# Each application stack (e.g., fleet-service) creates its own ALB and
# registers services with this cluster.

module "cluster" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "4.1.2"

  autoscaling_capacity_providers        = var.ecs_cluster.autoscaling_capacity_providers
  cluster_configuration                 = var.ecs_cluster.cluster_configuration
  cluster_name                          = var.name
  cluster_settings                      = var.ecs_cluster.cluster_settings
  create                                = var.ecs_cluster.create
  default_capacity_provider_use_fargate = var.ecs_cluster.default_capacity_provider_use_fargate
  fargate_capacity_providers            = var.ecs_cluster.fargate_capacity_providers
  tags                                  = merge(var.ecs_cluster.tags, local.tags)
}
