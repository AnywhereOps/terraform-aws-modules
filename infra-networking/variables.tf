variable "vpc" {
  description = "VPC configuration including CIDR blocks, subnets, NAT gateway settings, and DNS options."
  type = object({
    name                = optional(string, "infra")
    cidr                = optional(string, "10.10.0.0/16")
    azs                 = optional(list(string), ["us-east-2a", "us-east-2b", "us-east-2c"])
    private_subnets     = optional(list(string), ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"])
    public_subnets      = optional(list(string), ["10.10.11.0/24", "10.10.12.0/24", "10.10.13.0/24"])
    database_subnets    = optional(list(string), ["10.10.21.0/24", "10.10.22.0/24", "10.10.23.0/24"])
    elasticache_subnets = optional(list(string), ["10.10.31.0/24", "10.10.32.0/24", "10.10.33.0/24"])

    create_database_subnet_group              = optional(bool, false)
    create_database_subnet_route_table        = optional(bool, true)
    create_elasticache_subnet_group           = optional(bool, true)
    create_elasticache_subnet_route_table     = optional(bool, true)
    enable_vpn_gateway                        = optional(bool, false)
    single_nat_gateway                        = optional(bool, true) # false = HA (1 NAT per AZ)
    enable_nat_gateway                        = optional(bool, true)
    # DNS hostnames: gives public IPs a DNS name (ec2-X-X-X-X.region.compute.amazonaws.com)
    # Default false: Fargate/ALB don't need it. Set true if using Route 53 private hosted zones.
    enable_dns_hostnames = optional(bool, false)
    enable_dns_support   = optional(bool, true)
    logs_retention       = optional(number, 90)
  })
  default = {
    name                = "infra"
    cidr                = "10.10.0.0/16"
    azs                 = ["us-east-2a", "us-east-2b", "us-east-2c"]
    private_subnets     = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
    public_subnets      = ["10.10.11.0/24", "10.10.12.0/24", "10.10.13.0/24"]
    database_subnets    = ["10.10.21.0/24", "10.10.22.0/24", "10.10.23.0/24"]
    elasticache_subnets = ["10.10.31.0/24", "10.10.32.0/24", "10.10.33.0/24"]

    create_database_subnet_group              = false
    create_database_subnet_route_table        = true
    create_elasticache_subnet_group           = true
    create_elasticache_subnet_route_table     = true
    enable_vpn_gateway                        = false
    single_nat_gateway                        = true
    enable_nat_gateway                        = true
    enable_dns_hostnames = false
    enable_dns_support   = true
    logs_retention       = 90
  }
}