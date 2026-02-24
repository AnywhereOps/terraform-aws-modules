output "organization_id" {
  description = "The ID of the organization"
  value       = aws_organizations_organization.this.id
}

output "organization_arn" {
  description = "The ARN of the organization"
  value       = aws_organizations_organization.this.arn
}

output "organization_root_id" {
  description = "The ID of the organization root"
  value       = aws_organizations_organization.this.roots[0].id
}

output "master_account_id" {
  description = "The ID of the master account"
  value       = aws_organizations_organization.this.master_account_id
}

output "organizational_unit_ids" {
  description = "Map of OU names to OU IDs"
  value       = { for name, ou in aws_organizations_organizational_unit.this : name => ou.id }
}

output "organizational_unit_arns" {
  description = "Map of OU names to OU ARNs"
  value       = { for name, ou in aws_organizations_organizational_unit.this : name => ou.arn }
}
