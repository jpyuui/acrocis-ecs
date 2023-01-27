output "arn" {
  description = "作成したiam_roleのarn"
  value       = aws_iam_role.this.arn
}
