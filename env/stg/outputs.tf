output "alb_dns_name" {
  description = "ALBのDNS名"
  value       = module.alb.dns_name
}

output "cloudfront_web_url" {
  description = "CloudFront for Webのurl"
  value       = "https://${module.cloudfront_for_web.domain_name}"
}
