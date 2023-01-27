variable "name" {
  description = "このサービス/プロダクトの名前"
  type        = string
}

variable "env" {
  description = "Prod/Stgなどの環境"
  type        = string
}

variable "cluster_id" {
  description = "クラスターのID"
  type        = string
}

variable "launch_type" {
  description = "起動タイプ"
  type        = string
}

variable "service_config" {
  description = <<-EOF
    # service定義に関するconfig

    type = object(
    {
      name                   = string
      desired_count          = number
      enable_execute_command = bool
      network_config = map(
        object(
          {
            security_group_ids = list(string)
            subnet_ids         = list(string)
            assign_public_ip   = bool
          }
        )
      )
      load_balancer_config = map(
        object(
          {
            target_group_arn      = string
            container_name        = string
            container_port        = number
          }
        )
      )
    }
  )
  EOF
  type        = any
}

variable "task_config" {
  description = "task定義に関するconfig"
  type = object(
    {
      name                     = string
      execution_role_arn       = string
      task_role_arn            = string
      requires_compatibilities = list(string)
      network_mode             = string
      cpu                      = string
      memory                   = string
      container_definitions    = string
    }
  )
}
