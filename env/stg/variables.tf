variable "region" {
  description = "リージョン"
  type        = string
}

variable "default_tags" {
  description = "リソースへ共通で設定するタグ"
  type        = map(string)
}

variable "env" {
  description = "Prod/Stgなどの環境"
  type        = string
  default     = "stg"

  validation {
    condition     = contains(["stg"], var.env)
    error_message = "Only \"stg\" is allowed in this variable."
  }
}

variable "codestar_connection_arn" {
  description = "コンソールで作成したcodestarのconnectionのarn。pipelineで使用"
  type        = string
}

variable "web_app_repository_url" {

}

variable "subscriber_app_repository_url" {

}

variable "service_name" {
  description = "サービスの名前"
  type        = string
}

variable "developper_emails" {
  type = list(string)
}
