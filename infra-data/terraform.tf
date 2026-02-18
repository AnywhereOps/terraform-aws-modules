terraform {
  # Required for terraform-aws-modules/rds-aurora/aws v10.0+
  required_version = ">= 1.11"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.18"
    }
  }
}
