#
# GuardDuty Organization Admin Delegation
#
# Delegates GuardDuty administration to a designated account
# (typically the infra/security account, not org-root).
#

resource "aws_guardduty_organization_admin_account" "this" {
  admin_account_id = var.admin_account_id
}
