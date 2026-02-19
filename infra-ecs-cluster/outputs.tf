output "cluster" {
  value = {
    name = module.cluster.cluster_name
    arn  = module.cluster.cluster_arn
    id   = module.cluster.cluster_id
  }
}