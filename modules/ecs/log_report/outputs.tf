output "logger_log_group_name" {
  description = "FluentBit自体のログを管理するCloudWatchLogGroupの名前"
  value = aws_cloudwatch_log_group.for_logger.name
}

output "fluentbit_image_uri" {
  description = "FluentBitのカスタムイメージがあるECRのuri"
  value = aws_ecr_repository.fluentbit.repository_url
}

output "all_log_delivery_stream" {
  description = "全てのログストリームを処理するFirehoseの名前"
  value = aws_kinesis_firehose_delivery_stream.for_all_log.name
}

output "error_log_group_name" {
 description = "エラーログを管理するCloudWatchLogGroupの名前"
 value = aws_cloudwatch_log_group.for_app_error.name
}