terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.43"
    }
  }
  required_version = "~> 1.10"
}

# Replace these variables with the ones for your tests.
variable "test_inputs" {
  type = map(string)
  default = {
    first  = "test1"
    second = "test2"
  }
}

# Pass in any variables that the module requires.
# If your module has a `name` field don't forget to add some randomness.
module "basic_example" {
  source = "../../"
  inputs = var.test_inputs
}

# Replace this output with the one for your tests.
output "test_outputs" {
  value = module.basic_example.outputs
}
