# ===========================
# FluentBit
# ===========================
resource "aws_ecr_repository" "fluentbit" {
  name                 = "${var.producer_name}-fluentbit-${var.env}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "null_resource" "initial_image_push_fluentbit" {
  provisioner "local-exec" {
    command = <<-EOF
      docker build applications/log/fluentbit -t ${aws_ecr_repository.fluentbit.repository_url}:latest; \
      aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${aws_ecr_repository.fluentbit.repository_url}; \
      docker push ${aws_ecr_repository.fluentbit.repository_url}:latest;
    EOF

    on_failure = fail
  }

  depends_on = [
    aws_ecr_repository.fluentbit
  ]
}

# =================
# Cloud Watch
# =================

# FluentBitのログ
resource "aws_cloudwatch_log_group" "for_logger" {
  name              = "/aws/ecs/${var.producer_name}-logger-${var.env}"
  retention_in_days = 30
}
