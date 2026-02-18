locals {
  region = "us-east-2"
}

module "bootstrap" {
  source = "git::https://github.com/AnywhereOps-Forks/terraform-aws-bootstrap.git?ref=v0.1.0"

  account_alias = "anywhereops"
  region        = local.region
}