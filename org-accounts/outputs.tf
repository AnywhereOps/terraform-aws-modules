# Base account outputs
output "id_account_id" {
  description = "Account ID for the id account"
  value       = aws_organizations_account.id.id
}

output "infra_account_id" {
  description = "Account ID for the infra account"
  value       = aws_organizations_account.infra.id
}

# Additional accounts outputs
output "additional_account_ids" {
  description = "Map of additional account names to account IDs"
  value       = { for name, account in aws_organizations_account.additional : name => account.id }
}

output "additional_account_arns" {
  description = "Map of additional account names to account ARNs"
  value       = { for name, account in aws_organizations_account.additional : name => account.arn }
}

# Combined outputs
output "all_account_ids" {
  description = "Map of all account names to account IDs"
  value = merge(
    {
      "${var.org_name}-id"    = aws_organizations_account.id.id
      "${var.org_name}-infra" = aws_organizations_account.infra.id
    },
    { for name, account in aws_organizations_account.additional : name => account.id }
  )
}
