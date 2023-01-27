variable "name" {
  description = "roleの名前"
  type        = string
}

variable "assume_identifier" {
  description = "assumeしたいserviceの識別子"
  type        = string
}

variable "policy_arns" {
  description = <<-EOF
  # attachしたいservice-roleのarnのlist

  policy_arns = {
    service1 = {
      arn = "arn:service"
    }
    service2 = {
      arn = "arn:service"
    }
  }
  EOF

  type = map(
    object(
      {
        arn = string
      }
    )
  )
}
