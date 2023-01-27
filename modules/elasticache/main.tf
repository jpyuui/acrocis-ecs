resource "aws_elasticache_subnet_group" "cachesubnet" {
  name       = "${var.name}-cachesubnet-${var.env}"
  subnet_ids = var.subnet_ids
}

resource "aws_elasticache_replication_group" "this" {
  replication_group_id       = "${var.name}-elasticache-${var.env}"
  description                = "elasticache"
  node_type                  = var.node_type
  automatic_failover_enabled = true
  multi_az_enabled           = true
  engine                     = "redis"
  engine_version             = "5.0.6"
  parameter_group_name       = "default.redis5.0.cluster.on"
  subnet_group_name          = aws_elasticache_subnet_group.cachesubnet.name
  security_group_ids = [
    var.sg_id,
  ]
  num_node_groups         = var.num_cache_groups
  replicas_per_node_group = var.num_cache_replicas
}
