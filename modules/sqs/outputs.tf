output "url" {
  description = "The URL for the created Amazon SQS queue"
  value       = aws_sqs_queue.message_queue.url
}