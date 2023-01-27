variable "name" {
  description = "sgの名前"
  type        = string
}

variable "vpc_id" {
  description = "vpcのID"
  type        = string
}

variable "ingress_rules" {
  description = <<-EOF
  # ingress_ruleの定義一覧
      {
          http = {
            to_port      = 80
            from_port    = 80
            protocol     = "tcp"
            allow_cidrs = [
                "0.0.0.0/0",
            ]
          }
      }
  EOF
  type = map(
    object(
      {
        to_port     = number
        from_port   = number
        protocol    = string
        allow_cidrs = list(string)
      }
    )
  )
}

variable "egress_rules" {
  description = <<-EOF
  # egress_ruleの定義一覧
      {
          any = {
            to_port      = 0
            from_port    = 0
            protocol     = "-1"
            allow_cidrs = [
                "0.0.0.0/0",
            ]
          }
      }
  EOF
  type = map(
    object(
      {
        to_port     = number
        from_port   = number
        protocol    = string
        allow_cidrs = list(string)
      }
    )
  )
  default = {}
}
