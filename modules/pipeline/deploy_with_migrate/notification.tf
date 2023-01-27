# ====================================
# SNS Topic for Recive PipelineStatus
# ====================================
data "aws_iam_policy_document" "for_pipeline_sns" {
  statement {
    effect = "Allow"
    actions = [
      "SNS:Publish"
    ]

    principals {
      type        = "Service"
      identifiers = ["codestar-notifications.amazonaws.com"]
    }

    resources = [
      aws_sns_topic.receive_pipeline_status.arn
    ]
  }
}

resource "aws_sns_topic_policy" "receive_pipeline_status" {
  arn    = aws_sns_topic.receive_pipeline_status.arn
  policy = data.aws_iam_policy_document.for_pipeline_sns.json
}

resource "aws_sns_topic" "receive_pipeline_status" {
  name = "${var.name}-pipeline-status-receive-${var.env}"
}

resource "aws_sns_topic_subscription" "for_email_send" {
  topic_arn = aws_sns_topic.receive_pipeline_status.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.notifier.arn
}

resource "aws_codestarnotifications_notification_rule" "this" {
  name        = "${var.name}-pipeline-status-receive-${var.env}"
  resource    = aws_codepipeline.this.arn
  detail_type = "BASIC"
  event_type_ids = [
    "codepipeline-pipeline-pipeline-execution-failed",
    "codepipeline-pipeline-pipeline-execution-succeeded",
  ]

  target {
    address = aws_sns_topic.receive_pipeline_status.arn
  }
}


# =============================
# SNS Topic for Send Email
# =============================
resource "aws_sns_topic" "pipeline_notification_email" {
  name = "${var.name}-pipeline-notification-email-${var.env}"
}

resource "aws_sns_topic_subscription" "pipeline_notification_email" {
  for_each = { for email in var.notification_emails : email => email }

  topic_arn = aws_sns_topic.pipeline_notification_email.arn
  protocol  = "email"
  endpoint  = each.value
}


# =============================
# Lambda for Notification
# =============================
resource "aws_ecr_repository" "notifier" {
  name                 = "${var.name}-pipeline-status-notifier-${var.env}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "null_resource" "initial_image_push_notifier" {
  provisioner "local-exec" {
    command = <<-EOF
      docker build applications/pipeline/sns_status_notifier -t ${aws_ecr_repository.notifier.repository_url}:latest; \
      aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${aws_ecr_repository.notifier.repository_url}; \
      docker push ${aws_ecr_repository.notifier.repository_url}:latest;
    EOF

    on_failure = fail
  }

  depends_on = [
    aws_ecr_repository.notifier
  ]
}

resource "aws_lambda_function" "notifier" {
  function_name = "${var.name}-pipeline-status-notifier-${var.env}"
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.notifier.repository_url}:latest"
  role          = var.notifier_lambda_iam_role_arn
  memory_size   = 512
  timeout       = 300

  environment {
    variables = {
      REGION        = var.region
      SERVICE_NAME  = var.name
      SERVICE_ENV   = var.env
      SNS_TOPIC_ARN = aws_sns_topic.pipeline_notification_email.arn
      SUBJECT       = "【Pipeline】${var.name}-${var.env}"

    }
  }

  lifecycle {
    ignore_changes = [
      image_uri,
      last_modified,
    ]
  }

  depends_on = [
    null_resource.initial_image_push_notifier,
    aws_cloudwatch_log_group.for_notifier,
    aws_sns_topic.pipeline_notification_email
  ]
}

resource "aws_lambda_permission" "notifier" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notifier.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.receive_pipeline_status.arn
}

# Lambdaのログ
resource "aws_cloudwatch_log_group" "for_notifier" {
  name              = "/aws/lambda/${var.name}-pipeline-status-notifier-${var.env}"
  retention_in_days = 30
}
