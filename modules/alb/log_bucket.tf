# ======================
# S3 Bucket for ALB Log
# ======================
resource "aws_s3_bucket" "alb_log" {
  bucket        = "${var.name}-alb-log-${var.env}"
  force_destroy = false
}

resource "aws_s3_bucket_acl" "private" {
  bucket = aws_s3_bucket.alb_log.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "private" {
  bucket                  = aws_s3_bucket.alb_log.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.alb_log.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.alb_log.id

  rule {
    id     = "expires_in_180days"
    status = "Enabled"

    expiration {
      days = "180"
    }
  }
}

# ======================
# S3 Bucket Policy
# ======================
data "aws_elb_service_account" "this" {}

data "aws_iam_policy_document" "for_alb_log" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
    ]
    resources = [
      "${aws_s3_bucket.alb_log.arn}/${var.name}-${var.env}/AWSLogs/*",
    ]

    principals {
      type = "AWS"
      identifiers = [
        data.aws_elb_service_account.this.arn,
      ]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetBucketAcl",
    ]
    resources = [
      aws_s3_bucket.alb_log.arn,
    ]

    principals {
      type = "Service"
      identifiers = [
        "delivery.logs.amazonaws.com",
      ]
    }
  }
}

resource "aws_s3_bucket_policy" "for_alb_log" {
  bucket = aws_s3_bucket.alb_log.id
  policy = data.aws_iam_policy_document.for_alb_log.json
}
