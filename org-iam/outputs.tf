output "admin_user_arns" {
  description = "Map of admin user names to ARNs"
  value       = { for name, user in aws_iam_user.admins : name => user.arn }
}

output "admin_role_arn" {
  description = "ARN of the admin role"
  value       = var.create_admin_role ? aws_iam_role.admin[0].arn : null
}

output "admin_role_name" {
  description = "Name of the admin role"
  value       = var.create_admin_role ? aws_iam_role.admin[0].name : null
}

output "billing_role_arn" {
  description = "ARN of the billing role"
  value       = var.create_billing_role && var.billing_source_account_id != "" ? module.billing_role_access[0].iam_role_arn : null
}

output "admins_group_name" {
  description = "Name of the admins group"
  value       = length(var.admin_users) > 0 ? var.admin_group_name : null
}
