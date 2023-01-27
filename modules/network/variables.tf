variable "cidr" {
  description = "vpcのcidr_block"
  type        = string
}

variable "public_subnets" {
  description = <<-EOF
  # public subnetの定義リスト
  [
    {
      name = "foo",
      cidr = "10.0.1.0/24",
      az   = "ap-northeast-1a"
    }
  ]
  EOF
  type        = list(map(string))
}

variable "private_subnets" {
  description = <<-EOF
  # private subnetの定義リスト
  [
    {
      name = "bar"
      cidr = "10.0.65.0/24"
      az   = "ap-northeast-1a"
    }
  ]
  EOF
  type        = list(map(string))
}
