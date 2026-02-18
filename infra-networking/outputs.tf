output "vpc" {
  description = "All VPC outputs from terraform-aws-modules/vpc/aws"
  value       = module.vpc
}

output "nat_eips" {
  description = "List of EIPs for NAT gateways."
  value       = aws_eip.nat[*].id
}
