variable "name" {
  description = "このサービス/プロダクトの名前"
  type        = string
}

variable "env" {
  description = "Prod/Stgなどの環境"
  type        = string
}

variable "execution_role_arn" {
  description = "taskの実行マネージャーに付与するiam_role"
  type        = string
}

variable "task_role_arn" {
  description = "taskのコンテナに付与するiam_role"
  type        = string
}

variable "launch_type" {
  description = "起動タイプ"
  type        = string
}

variable "requires_compatibilities" {
  description = "利用するFARGATEなどのデータプレーン"
  type        = list(string)
}

variable "network_mode" {
  description = "ネットワークモード。FARGATEの場合はawsvpcとする"
  type        = string
}

variable "cpu" {
  description = "割り当てるCPU"
  type        = string
}

variable "memory" {
  description = "割り当てるメモリ"
  type        = string
}

variable "container_definitions" {
  description = "task定義"
  type        = string
}
