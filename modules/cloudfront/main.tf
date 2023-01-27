# =================
# CloudFront
# =================
resource "aws_cloudfront_distribution" "this" {
  enabled         = true
  is_ipv6_enabled = true

  origin {
    domain_name         = var.domain_name
    origin_id           = var.origin_id
    connection_attempts = 3
    connection_timeout  = 10

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_keepalive_timeout = 5
      origin_protocol_policy   = "http-only"
      origin_read_timeout      = 30
      origin_ssl_protocols = [
        "TLSv1",
        "TLSv1.1",
        "TLSv1.2", # cloudfront <-> ALB間のssl対応時にTLSv1.2のみにする
      ]
    }

    dynamic "custom_header" {
      for_each = var.custom_origin_headers

      content {
        name  = custom_header.value.name
        value = custom_header.value.value
      }
    }
  }

  default_cache_behavior {
    allowed_methods        = ["HEAD", "OPTIONS", "GET", "PUT", "POST", "DELETE", "PATCH"]
    cached_methods         = ["HEAD", "OPTIONS", "GET"]
    compress               = true
    default_ttl            = 86400    # デフォルトの1日を明示的に指定。
    max_ttl                = 31536000 # デフォルトの365日を明示的に指定。
    min_ttl                = 0        # デフォルトの0sを明示的に指定。
    smooth_streaming       = false
    target_origin_id       = var.origin_id
    trusted_signers        = []
    viewer_protocol_policy = "https-only"

    forwarded_values {
      query_string = true
      headers = [
        "*"
      ]

      cookies {
        forward = "all"
      }
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}


