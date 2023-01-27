variable "name" {
  description = "このサービス/プロダクトの名前"
  type        = string
}

variable "env" {
  description = "Prod/Stgなどの環境"
  type        = string
}

variable "vpc_id" {
  description = "VPCのID"
  type        = string
}

variable "subnet_ids" {
  description = "ALBが属するsubnetのidリスト"
  type        = list(string)
}

variable "security_group_ids" {
  description = "ALBへ紐づけるSecurityGroupのidリスト"
  type        = list(string)
}

variable "target_groups" {
  type = map(
    object(
      {
        name_prefix          = string
        target_type          = string
        port                 = number
        protocol             = string
        deregistration_delay = number
        health_check_config  = map(any)
      }
    )
  )
}

variable "listeners" {
  description = <<-EOF
  map(
    object(
      {
        port     = string
        protocol = string
        certificate_arn = string #OPTIONAL
        ssl_policy = string # OPTIONAL
        rules = map(
          object(
            {
              type     = string
              priority = number
              fixed_response_config = map{
                  message_body = string
                  status_code  = string
                  content_type = string
                } #OPTIONAL
              forward_config = map{
                  target_group_name = string
                } #OPTIONAL
              redirect_config = map{
                  port        = string
                  protocol    = string
                  status_code = string
                  host        = string
                  path        = string
                  query       = string
                } #OPTIONAL
              conditions = object(
                {
                  path_patterns = list(string) #OPTIONAL
                  http_headers = map(
                    object(
                      {
                        name   = string
                        values = list(string)
                      }
                    )
                  ) #OPTIONAL
                }
              )
            }
          )
        )
      }
    )
  )
  EOF
  type        = any
}

