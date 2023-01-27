resource "aws_ssm_parameter" "this" {
  name        = var.name
  description = var.description
  type        = "SecureString"
  value       = var.dummy_value

  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}
