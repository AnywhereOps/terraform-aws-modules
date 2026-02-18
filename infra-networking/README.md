Creates a VPC with three availability zones, static EIPs for NAT gateways,
VPC flow logs, and a locked-down default security group.

## Usage

```hcl
module "networking" {
  source = "../../modules/networking"

  vpc = {
    name = "production"
    cidr = "10.20.0.0/16"
    azs  = ["us-east-2a", "us-east-2b", "us-east-2c"]

    private_subnets     = ["10.20.1.0/24", "10.20.2.0/24", "10.20.3.0/24"]
    public_subnets      = ["10.20.11.0/24", "10.20.12.0/24", "10.20.13.0/24"]
    database_subnets    = ["10.20.21.0/24", "10.20.22.0/24", "10.20.23.0/24"]
    elasticache_subnets = ["10.20.31.0/24", "10.20.32.0/24", "10.20.33.0/24"]

    single_nat_gateway = false  # Set true for cost savings (not HA)
  }
}
```

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
| vpc | terraform-aws-modules/vpc/aws | ~> 3.19.0 |

## Resources

| Name | Type |
|------|------|
| [aws_default_security_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_security_group) | resource |
| [aws_eip.nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cidr\_slash16 | First 2 octects of the /16 CIDR to use for the VPC. | `string` | n/a | yes |
| environment | Environment name | `string` | n/a | yes |
| region | AWS region | `string` | n/a | yes |
| single\_nat\_gateway | Whether to define a single NAT gateway for all AZs | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| database\_subnets | List of IDs of DB subnets. |
| nat\_eips | List of EIPs for NAT gateways. |
| private\_subnets | List of IDs of private subnets. |
| public\_subnets | List of IDs of public subnets. |
| vpc\_id | The ID of the VPC. |
| vpc\_name | The name of the VPC. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
