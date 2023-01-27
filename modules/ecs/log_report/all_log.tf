locals {
  lambda_func_name = "${var.producer_name}-all-log-data-processer-${var.env}"
}


# =================
# Firehose
# =================
resource "aws_kinesis_firehose_delivery_stream" "for_all_log" {
  name        = "${var.producer_name}-stream-${var.env}"
  destination = "extended_s3"

  extended_s3_configuration {
    bucket_arn = aws_s3_bucket.all_log.arn
    role_arn   = var.firehose_iam_role_arn

    processing_configuration {
      enabled = "true"

      processors {
        type = "Lambda"

        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = "${aws_lambda_function.all_log_data_processer.arn}:$LATEST"
        }
      }
    }

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.for_all_log_firehose.name
      log_stream_name = "firehose_error"
    }
  }

  depends_on = [
    aws_lambda_function.all_log_data_processer
  ]
}

# Firehose自体のログ
resource "aws_cloudwatch_log_group" "for_all_log_firehose" {
  name              = "/aws/kinesis/${var.producer_name}-all-log-firehose-${var.env}"
  retention_in_days = 30
}


# ===========================
# Lambda for Data Processing
# ===========================
resource "aws_ecr_repository" "all_log_data_processer" {
  name                 = "${var.producer_name}-all-log-data-processer-${var.env}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "null_resource" "initial_image_push_all_log_data_processer" {
  provisioner "local-exec" {
    command = <<-EOF
      docker build applications/log/firehose/fluentbit_log_processer -t ${aws_ecr_repository.all_log_data_processer.repository_url}:latest; \
      aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${aws_ecr_repository.all_log_data_processer.repository_url}; \
      docker push ${aws_ecr_repository.all_log_data_processer.repository_url}:latest;
    EOF

    on_failure = fail
  }

  depends_on = [
    aws_ecr_repository.all_log_data_processer
  ]
}

resource "aws_lambda_function" "all_log_data_processer" {
  function_name = local.lambda_func_name
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.all_log_data_processer.repository_url}:latest"
  role          = var.data_processer_lambda_iam_role_arn
  memory_size   = 512
  timeout       = 300

  lifecycle {
    ignore_changes = [
      image_uri,
      last_modified,
    ]
  }

  depends_on = [
    null_resource.initial_image_push_all_log_data_processer,
    aws_cloudwatch_log_group.for_all_log_data_processer
  ]
}

# Firehoseからのデータを変換するLambdaのログ
resource "aws_cloudwatch_log_group" "for_all_log_data_processer" {
  name              = "/aws/lambda/${local.lambda_func_name}"
  retention_in_days = 30
}


# =================
# S3 Log Bucket
# =================
resource "aws_s3_bucket" "all_log" {
  bucket        = "${var.producer_name}-log-${var.env}"
  force_destroy = false
}

resource "aws_s3_bucket_acl" "private_for_all_log" {
  bucket = aws_s3_bucket.all_log.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "for_all_log" {
  bucket                  = aws_s3_bucket.all_log.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "for_all_log" {
  bucket = aws_s3_bucket.all_log.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
