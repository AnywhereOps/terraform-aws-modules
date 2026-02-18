plugin "terraform" {
  enabled = true
  preset  = "all"
}

plugin "opa" {
  enabled = false
  version = "0.7.0"
  source  = "github.com/terraform-linters/tflint-ruleset-opa"
}


plugin "aws" {
    enabled = true
    version = "0.38.0"
    source  = "github.com/terraform-linters/tflint-ruleset-aws"
}







