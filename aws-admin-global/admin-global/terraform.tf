terraform {
  required_version = "~> 1.10"

  backend "s3" {
    bucket       = "anywhereops-tf-state-us-east-2"
    key          = "terraform-aws-modules/admin-global/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }
}
