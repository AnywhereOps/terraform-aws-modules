# Default CIDR Allocation (10.10.0.0/16)
# ======================================
# Each subnet type gets a /24 per AZ (254 usable IPs each)
#
# Private subnets (workloads):
#   10.10.1.0/24  - AZ A
#   10.10.2.0/24  - AZ B
#   10.10.3.0/24  - AZ C
#
# Public subnets (load balancers, NAT):
#   10.10.11.0/24 - AZ A
#   10.10.12.0/24 - AZ B
#   10.10.13.0/24 - AZ C
#
# Database subnets (RDS, Aurora):
#   10.10.21.0/24 - AZ A
#   10.10.22.0/24 - AZ B
#   10.10.23.0/24 - AZ C
#
# Elasticache subnets (Redis, Memcached):
#   10.10.31.0/24 - AZ A
#   10.10.32.0/24 - AZ B
#   10.10.33.0/24 - AZ C
#

# By default, the VPC module creates EIPs for the NAT gateways that it
# will use ephemerally; so if we make changes to the VPC, it can tear
# down those EIPs and recreate them, changing the EIPs. However, we can
# create those separately and then pass them to the VPC module instead,
# and then changes to the VPC will not affect the NAT gateways.
#
# Why do this? Some clients will be interfacing with external partners
# that need to whitelist things by IP; if this is getting changed, we
# have to jump through hoops with these partners to update their
# firewalls. Creating these EIPs separately saves us from needing to
# do this.

resource "aws_eip" "nat" {
  count  = var.vpc.single_nat_gateway ? 1 : length(var.vpc.azs)
  domain = "vpc"

  lifecycle {
    prevent_destroy = true
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.5.0"

  name = var.vpc.name
  cidr = var.vpc.cidr

  # For non-prod environments, set azs to a single AZ to reduce costs
  azs                                   = var.vpc.azs
  private_subnets                       = var.vpc.private_subnets
  public_subnets                        = var.vpc.public_subnets
  database_subnets                      = var.vpc.database_subnets
  elasticache_subnets                   = var.vpc.elasticache_subnets
  create_database_subnet_group          = var.vpc.create_database_subnet_group
  create_database_subnet_route_table    = var.vpc.create_database_subnet_route_table
  create_elasticache_subnet_group       = var.vpc.create_elasticache_subnet_group
  create_elasticache_subnet_route_table = var.vpc.create_elasticache_subnet_route_table
  enable_vpn_gateway                    = var.vpc.enable_vpn_gateway
  single_nat_gateway                    = var.vpc.single_nat_gateway
  one_nat_gateway_per_az                = !var.vpc.single_nat_gateway # Derived: HA when not single
  enable_nat_gateway                    = var.vpc.enable_nat_gateway
  reuse_nat_ips                         = true
  external_nat_ips                      = aws_eip.nat[*].id
  enable_dns_hostnames                  = var.vpc.enable_dns_hostnames
  enable_dns_support                    = var.vpc.enable_dns_support
}

module "vpc_flow_logs" {
  source  = "trussworks/vpc-flow-logs/aws"
  version = "~> 2.0"

  vpc_name       = var.vpc.name
  vpc_id         = module.vpc.vpc_id
  logs_retention = var.vpc.logs_retention
}

# Remove the permissiveness of the default SG that's created by AWS.
resource "aws_default_security_group" "default" {
  vpc_id = module.vpc.vpc_id

  # We have to specify at least one rule, otherwise the default rules will
  # remain. We use ICMP Destination Unreachable as the dummy entry.
  ingress {
    description = "Dummy rule; need one"

    protocol  = 1 # ICMP
    from_port = 3 # Destination Unreachable
    to_port   = 0
    self      = true
  }
}
