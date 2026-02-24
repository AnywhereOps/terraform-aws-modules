#
# AWS Organization
#
# This module creates the AWS Organization with configurable service access
# principals and feature set.
#

resource "aws_organizations_organization" "this" {
  aws_service_access_principals = var.service_access_principals
  enabled_policy_types          = var.enabled_policy_types
  feature_set                   = var.feature_set
}

#
# Organizational Units
#

resource "aws_organizations_organizational_unit" "this" {
  for_each = var.organizational_units

  name      = each.key
  parent_id = coalesce(each.value.parent_id, aws_organizations_organization.this.roots[0].id)

  tags = merge(var.tags, each.value.tags)
}
