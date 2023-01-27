resource "aws_sqs_queue" "message_queue" {
  name                      = "message_queue_${var.env}"
  delay_seconds             = 0
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 20
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.message_queue_deadletter.arn
    maxReceiveCount     = 4
  })
  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns   = ["${aws_sqs_queue.message_queue_deadletter.arn}"]
  })
}

resource "aws_sqs_queue" "message_queue_deadletter" {
  name                      = "message_queue_deadletter_${var.env}"
  delay_seconds             = 0
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 20

  tags = {
    Environment = "${var.env}"
  }
}

