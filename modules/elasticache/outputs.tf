output "endpoint" {
  description = "作成したelasticacheのendpoint"
  value       = aws_elasticache_replication_group.this.configuration_endpoint_address
}

output "port" {
  description = "redisが使用するport"
  value = aws_elasticache_replication_group.this.port
}
