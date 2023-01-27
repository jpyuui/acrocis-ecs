variable "name" {
  description = "name"
  type        = string
}

variable "subnet_ids" {
  description = "subnet id list"
  type        = list(string)
}

variable "cidr_blocks" {
  description = "ingress allow cidr block"
  type        = string
}

variable "vpc_id" {
  description = "vpc id"
  type        = string
}

variable "env" {
  description = "stg|prod"
  type        = string
}

variable "num_cache_groups" {
  description = "number_cache_groups"
  type        = number
}

variable "num_cache_replicas" {
  description = "number_cache_replicas"
  type        = number
}

variable "node_type" {
  description = "node type"
  type        = string
}

variable "sg_id" {
  description = "security group id"
  type        = string
}