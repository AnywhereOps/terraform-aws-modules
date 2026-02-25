# Networking - VPC + subnets + NAT

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "git::https://github.com/AnywhereOps/terraform-aws-modules.git//infra-networking?ref=main"
}

dependency "admin_global" {
  config_path = "../admin-global"
  skip_outputs = true  # Just need it to exist first
}

inputs = {
  vpc = {
    name            = "tradewitme"
    cidr            = "10.20.0.0/16"
    azs             = ["us-east-1a", "us-east-1b"]
    private_subnets = ["10.20.1.0/24", "10.20.2.0/24"]
    public_subnets  = ["10.20.11.0/24", "10.20.12.0/24"]

    # Cost optimization: single AZ NAT for now
    single_nat_gateway = true
    enable_nat_gateway = true

    # Don't need DB/cache subnets for this project
    database_subnets    = []
    elasticache_subnets = []
    create_database_subnet_group   = false
    create_elasticache_subnet_group = false
  }
}
