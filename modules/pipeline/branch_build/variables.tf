variable "name" {
  description = "アプリの名前"
  type        = string
}

variable "env" {
  description = "Prod/Stgなどの環境"
  type        = string
}

variable "repository_url" {
  description = "https形式のリポジトリURL"
  type        = string
}

variable "code_build_iam_role_arn" {
  description = "code_buildへ付与するiam_roleのarn"
  type        = string
}
