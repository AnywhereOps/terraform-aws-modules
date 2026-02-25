# Admin Global - logs bucket, Config, cross-account roles

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "git::https://github.com/AnywhereOps/terraform-aws-modules.git//admin-global?ref=main"
}

inputs = {
  core_infra     = false  # No Route53/GuardDuty for tradewitme
  logging_bucket = "tradewitme-prod-aws-logs"
  region         = "us-east-1"

  # These come from AnywhereOps org - adjust as needed
  account_id_org_root = "551828037835"
  account_id_id       = "853411135567"
  email_org_root      = "Andrew@anywhereops.ai"
  email_id            = "anywhereops-infra+id@truss.works"
}
