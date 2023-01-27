variable "producer_name" {
  description = "ログを出力するアプリの名前"
  type        = string
}

variable "env" {
  description = "Prod/Stgなどの環境"
  type        = string
}

variable "region" {
  description = "リージョン"
  type        = string
}

variable "firehose_iam_role_arn" {
  description = "Firehoseに付与するiam_roleのarn"
  type        = string
}

variable "data_processer_lambda_iam_role_arn" {
  description = "データ変換用Lambdaに付与するiam_roleのarn"
  type        = string
}


variable "cloudwatch_to_firehose_iam_role_arn" {
  description = "firehoseを対象にしたcloudwatchのサブスクリプションフィルターに付与するiam_roleのarn"
  type        = string
}

variable "error_notifier_lambda_iam_role_arn" {
  description = "lambdaを対象にしたcloudwatchのサブスクリプションフィルターに付与するiam_roleのarn"
  type        = string
}

variable "notification_emails" {
  description = "SNSでメール通知する対象のメールアドレス"
  type        = list(string)
}
