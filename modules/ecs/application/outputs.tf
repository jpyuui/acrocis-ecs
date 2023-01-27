output "service_name" {
  description = "サービスの名前"
  value       = aws_ecs_service.this.name
}
