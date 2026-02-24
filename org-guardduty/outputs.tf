output "admin_account_id" {
  description = "The delegated GuardDuty admin account ID"
  value       = aws_guardduty_organization_admin_account.this.admin_account_id
}
