variable "name" {
  description = "/db/pass, のような、設定したい一意なkeyの指定"
  type        = string
}

variable "dummy_value" {
  description = "initializeのためのダミーの値"
  type        = string
  default     = "this_is_dummy_value"
}

variable "description" {
  description = "このparameterの説明"
  type        = string
}
