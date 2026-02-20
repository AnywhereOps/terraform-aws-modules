# Route53 zone for domain
# Only created when core_infra = true

resource "aws_route53_zone" "zone" {
  count = var.core_infra ? 1 : 0
  name  = "${var.domain}."
}

# Query logging (requires us-east-1 provider)
module "query_logging" {
  count   = var.core_infra ? 1 : 0
  source  = "trussworks/route53-query-logs/aws"
  version = "~> 4.0.0"

  providers = { aws.us-east-1 = aws.us-east-1 }

  zone_id                   = aws_route53_zone.zone[0].zone_id
  logs_cloudwatch_retention = var.log_retention_days
}
