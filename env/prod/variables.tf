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
  default     = "prod"

  validation {
    condition     = contains(["prod"], var.env)
    error_message = "Only \"prod\" is allowed in this variable."
  }
}

variable "service_name" {
  description = "サービスの名前"
  type        = string
}

variable "developper_emails" {
  type = list(string)
}
