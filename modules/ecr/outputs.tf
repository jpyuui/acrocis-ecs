output "name" {
  value = aws_ecr_repository.this.name
}

output "image_uri" {
  value = "${aws_ecr_repository.this.repository_url}:release"
}
