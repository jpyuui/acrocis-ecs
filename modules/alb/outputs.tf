output "dns_name" {
  description = "ALBのDNS名"
  value       = aws_alb.this.dns_name
}

output "id" {
  description = "ALBのID"
  value       = aws_alb.this.id
}

output "zone_id" {
  description = "zone id"
  value       = aws_alb.this.zone_id
}

output "target_groups" {
  description = "TargetGroupの一覧"
  value       = aws_alb_target_group.this
}
