output "name" {
  description = "database名"
  value       = aws_rds_cluster.this.database_name
}

output "host" {
  description = "database host"
  value       = aws_rds_cluster.this.endpoint
}
