output "route53_zones" {
  description = "Map of domain -> zone details (only when core_infra = true)"
  value = var.core_infra ? {
    for domain, zone in aws_route53_zone.zones : domain => {
      zone_id      = zone.zone_id
      name_servers = zone.name_servers
    }
  } : {}
}
