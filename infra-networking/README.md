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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.27.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | 6.5.0 |
| <a name="module_vpc_flow_logs"></a> [vpc\_flow\_logs](#module\_vpc\_flow\_logs) | trussworks/vpc-flow-logs/aws | ~> 2.0 |

## Resources

| Name | Type |
|------|------|
| [aws_default_security_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_security_group) | resource |
| [aws_eip.nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_vpc"></a> [vpc](#input\_vpc) | VPC configuration including CIDR blocks, subnets, NAT gateway settings, and DNS options. | <pre>object({<br/>    name                = optional(string, "infra")<br/>    cidr                = optional(string, "10.10.0.0/16")<br/>    azs                 = optional(list(string), ["us-east-2a", "us-east-2b", "us-east-2c"])<br/>    private_subnets     = optional(list(string), ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"])<br/>    public_subnets      = optional(list(string), ["10.10.11.0/24", "10.10.12.0/24", "10.10.13.0/24"])<br/>    database_subnets    = optional(list(string), ["10.10.21.0/24", "10.10.22.0/24", "10.10.23.0/24"])<br/>    elasticache_subnets = optional(list(string), ["10.10.31.0/24", "10.10.32.0/24", "10.10.33.0/24"])<br/><br/>    create_database_subnet_group          = optional(bool, false)<br/>    create_database_subnet_route_table    = optional(bool, true)<br/>    create_elasticache_subnet_group       = optional(bool, true)<br/>    create_elasticache_subnet_route_table = optional(bool, true)<br/>    enable_vpn_gateway                    = optional(bool, false)<br/>    single_nat_gateway                    = optional(bool, true) # false = HA (1 NAT per AZ)<br/>    enable_nat_gateway                    = optional(bool, true)<br/>    # DNS hostnames: gives public IPs a DNS name (ec2-X-X-X-X.region.compute.amazonaws.com)<br/>    # Default false: Fargate/ALB don't need it. Set true if using Route 53 private hosted zones.<br/>    enable_dns_hostnames = optional(bool, false)<br/>    enable_dns_support   = optional(bool, true)<br/>    logs_retention       = optional(number, 90)<br/>  })</pre> | <pre>{<br/>  "azs": [<br/>    "us-east-2a",<br/>    "us-east-2b",<br/>    "us-east-2c"<br/>  ],<br/>  "cidr": "10.10.0.0/16",<br/>  "create_database_subnet_group": false,<br/>  "create_database_subnet_route_table": true,<br/>  "create_elasticache_subnet_group": true,<br/>  "create_elasticache_subnet_route_table": true,<br/>  "database_subnets": [<br/>    "10.10.21.0/24",<br/>    "10.10.22.0/24",<br/>    "10.10.23.0/24"<br/>  ],<br/>  "elasticache_subnets": [<br/>    "10.10.31.0/24",<br/>    "10.10.32.0/24",<br/>    "10.10.33.0/24"<br/>  ],<br/>  "enable_dns_hostnames": false,<br/>  "enable_dns_support": true,<br/>  "enable_nat_gateway": true,<br/>  "enable_vpn_gateway": false,<br/>  "logs_retention": 90,<br/>  "name": "infra",<br/>  "private_subnets": [<br/>    "10.10.1.0/24",<br/>    "10.10.2.0/24",<br/>    "10.10.3.0/24"<br/>  ],<br/>  "public_subnets": [<br/>    "10.10.11.0/24",<br/>    "10.10.12.0/24",<br/>    "10.10.13.0/24"<br/>  ],<br/>  "single_nat_gateway": true<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_nat_eips"></a> [nat\_eips](#output\_nat\_eips) | List of EIPs for NAT gateways. |
| <a name="output_vpc"></a> [vpc](#output\_vpc) | All VPC outputs from terraform-aws-modules/vpc/aws |
<!-- END_TF_DOCS -->