variable "domain_name" {
  description = "ドメインネーム"
  type        = string
}

variable "origin_id" {
  description = "オリジンとするリソースのID"
  type        = string
}

variable "custom_origin_headers" {
  description = "cloudfrontに付与させたいカスタムヘッダー。"
  type = map(
    object(
      {
        name  = string
        value = string
      }
    )
  )
  default = {}
}
