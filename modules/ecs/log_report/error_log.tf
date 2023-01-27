locals {
  data_processer_lambda_func_name = "${var.producer_name}-error-log-data-processer-${var.env}"
  error_notifier_lambda_func_name = "${var.producer_name}-error-notifier-${var.env}"
}


# =================
# Cloud Watch
# =================

# アプリのエラーログ
resource "aws_cloudwatch_log_group" "for_app_error" {
  name              = "/aws/ecs/${var.producer_name}-errors-${var.env}"
  retention_in_days = 30
}

# 通知用のLambdaへ流す
resource "aws_cloudwatch_log_subscription_filter" "for_error_notification" {
  name            = "${var.producer_name}-error-notification-${var.env}"
  log_group_name  = aws_cloudwatch_log_group.for_app_error.name
  filter_pattern  = ""
  destination_arn = aws_lambda_function.error_notifier.arn

  depends_on = [
    aws_lambda_permission.error_notifier
  ]
}

# 永続化用のFirehoseへ流す
resource "aws_cloudwatch_log_subscription_filter" "for_firehose" {
  name            = "${var.producer_name}-error-store-${var.env}"
  log_group_name  = aws_cloudwatch_log_group.for_app_error.name
  filter_pattern  = ""
  destination_arn = aws_kinesis_firehose_delivery_stream.for_error_log.arn
  role_arn        = var.cloudwatch_to_firehose_iam_role_arn
}


# =============================
# Lambda for ErrorNotification
# =============================
resource "aws_ecr_repository" "error_notifier" {
  name                 = local.error_notifier_lambda_func_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "null_resource" "initial_image_push_error_notifier" {
  provisioner "local-exec" {
    command = <<-EOF
      docker build applications/log/sns_error_notifier -t ${aws_ecr_repository.error_notifier.repository_url}:latest; \
      aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${aws_ecr_repository.error_notifier.repository_url}; \
      docker push ${aws_ecr_repository.error_notifier.repository_url}:latest;
    EOF

    on_failure = fail
  }

  depends_on = [
    aws_ecr_repository.error_notifier
  ]
}

resource "aws_lambda_function" "error_notifier" {
  function_name = local.error_notifier_lambda_func_name
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.error_notifier.repository_url}:latest"
  role          = var.error_notifier_lambda_iam_role_arn
  memory_size   = 512
  timeout       = 300

  environment {
    variables = {
      REGION        = var.region
      SERVICE_NAME  = var.producer_name
      SERVICE_ENV   = var.env
      SNS_TOPIC_ARN = aws_sns_topic.error_notification.arn
      SUBJECT       = "【Error】${var.producer_name}-${var.env}"

    }
  }

  lifecycle {
    ignore_changes = [
      image_uri,
      last_modified,
    ]
  }

  depends_on = [
    null_resource.initial_image_push_error_notifier,
    aws_cloudwatch_log_group.for_error_notifier,
    aws_sns_topic.error_notification
  ]
}

resource "aws_lambda_permission" "error_notifier" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.error_notifier.function_name
  principal     = "logs.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.for_app_error.arn}:*"
}

# Error通知を行うLambdaのログ
resource "aws_cloudwatch_log_group" "for_error_notifier" {
  name              = "/aws/lambda/${local.error_notifier_lambda_func_name}"
  retention_in_days = 30
}


# ===============================
# SNS for ErrorNotification　Email
# ===============================

resource "aws_sns_topic" "error_notification" {
  name = "${var.producer_name}-error-notification-${var.env}"
}

resource "aws_sns_topic_subscription" "this" {
  for_each  = { for email in var.notification_emails : email => email }

  topic_arn = aws_sns_topic.error_notification.arn
  protocol  = "email"
  endpoint  = each.value
}


# =================
# Firehose
# =================
resource "aws_kinesis_firehose_delivery_stream" "for_error_log" {
  name        = "${var.producer_name}-error-stream-${var.env}"
  destination = "extended_s3"

  extended_s3_configuration {
    bucket_arn = aws_s3_bucket.for_error_log.arn
    role_arn   = var.firehose_iam_role_arn

    processing_configuration {
      enabled = "true"

      processors {
        type = "Lambda"

        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = "${aws_lambda_function.error_log_data_processer.arn}:$LATEST"
        }
      }
    }

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.for_error_log_firehose.name
      log_stream_name = "firehose_error"
    }
  }

  depends_on = [
    aws_lambda_function.error_log_data_processer
  ]
}

# Firehose自体のログ
resource "aws_cloudwatch_log_group" "for_error_log_firehose" {
  name              = "/aws/kinesis/${var.producer_name}-error-log-firehose-${var.env}"
  retention_in_days = 30
}


# ===========================
# Lambda for Data Processing
# ===========================
resource "aws_ecr_repository" "error_log_data_processer" {
  name                 = local.data_processer_lambda_func_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "null_resource" "initial_image_push_error_log_data_processer" {
  provisioner "local-exec" {
    command = <<-EOF
      docker build applications/log/firehose/cwl_log_processer -t ${aws_ecr_repository.error_log_data_processer.repository_url}:latest; \
      aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${aws_ecr_repository.error_log_data_processer.repository_url}; \
      docker push ${aws_ecr_repository.error_log_data_processer.repository_url}:latest;
    EOF

    on_failure = fail
  }

  depends_on = [
    aws_ecr_repository.error_log_data_processer
  ]
}

resource "aws_lambda_function" "error_log_data_processer" {
  function_name = local.data_processer_lambda_func_name
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.error_log_data_processer.repository_url}:latest"
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
    null_resource.initial_image_push_error_log_data_processer,
    aws_cloudwatch_log_group.for_error_log_data_processer
  ]
}

# Firehoseからのデータを変換するLambdaのログ
resource "aws_cloudwatch_log_group" "for_error_log_data_processer" {
  name              = "/aws/lambda/${local.data_processer_lambda_func_name}"
  retention_in_days = 30
}


# =================
# S3 Log Bucket
# =================
resource "aws_s3_bucket" "for_error_log" {
  bucket        = "${var.producer_name}-error-log-${var.env}"
  force_destroy = false
}

resource "aws_s3_bucket_acl" "for_error_log" {
  bucket = aws_s3_bucket.for_error_log.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "for_error_log" {
  bucket                  = aws_s3_bucket.for_error_log.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "for_error_log" {
  bucket = aws_s3_bucket.for_error_log.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
