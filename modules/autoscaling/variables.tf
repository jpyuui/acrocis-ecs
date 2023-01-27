variable "cluster" {
  description = "ecs cluster name"
  type        = string
}

variable "service" {
  description = "ecs service name"
  type        = string
}

variable "max_capacity" {
  description = "ecs task maxium number"
  type        = number
}

variable "min_capacity" {
  description = "ecs task minimum number"
  type        = number
}

variable "role_arn" {
  description = "ecs autoscaling role arn"
  type        = string
}
