# Route53 zones for domains
# Only created when core_infra = true

resource "aws_route53_zone" "zones" {
  for_each = var.core_infra ? toset(var.domains) : toset([])
  name     = "${each.value}."
}

# Query logging for each zone (requires us-east-1 provider)
module "query_logging" {
  for_each = var.core_infra ? toset(var.domains) : toset([])
  source   = "trussworks/route53-query-logs/aws"
  version  = "~> 4.0.0"

  providers = { aws.us-east-1 = aws.us-east-1 }

  zone_id                   = aws_route53_zone.zones[each.key].zone_id
  logs_cloudwatch_retention = var.log_retention_days
}
