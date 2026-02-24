output "custom_scp_ids" {
  description = "Map of custom SCP names to IDs"
  value       = { for name, scp in aws_organizations_policy.custom : name => scp.id }
}

output "custom_scp_arns" {
  description = "Map of custom SCP names to ARNs"
  value       = { for name, scp in aws_organizations_policy.custom : name => scp.arn }
}
