variable "name" {
  description = "roleの名前"
  type        = string
}

variable "assume_identifier" {
  description = "assumeしたいserviceの識別子"
  type        = string
}

variable "policy" {
  description = "policyのjson"
  type        = string
}
