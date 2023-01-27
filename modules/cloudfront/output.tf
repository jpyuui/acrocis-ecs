output "domain_name" {
  description = "cloudfrontのdomain_name"
  value       = aws_cloudfront_distribution.this.domain_name
}
