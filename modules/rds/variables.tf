variable "name" {
  description = "このサービス/プロダクトの名前"
  type        = string
}

variable "env" {
  description = "Prod/Stgなどの環境"
  type        = string
}

variable "family" {
  description = "parameter-groupに設定するfamily"
  type        = string
}

variable "engine" {
  description = "DBで使用するengine"
  type        = string
}

variable "engine_version" {
  description = "enginenのバージョン。var.familyで指定したversionと互換性があるものを指定"
  type        = string
}

variable "port" {
  description = "DBが利用するport"
  type        = number
}

variable "timezone" {
  description = "DB Engineに設定するTimezone"
  type        = string
}

variable "char_code" {
  description = "DB Engineに設定する文字コード"
  type        = string
}

variable "instance_names" {
  description = "cluster内に立ち上げるinstanceの名前のlist。入れた名前分インスタンスが作成される"
  type        = list(string)
}

variable "instance_class" {
  description = "db.t3.smallのようなinstanceクラスの指定"
  type        = string
}

variable "security_group_id" {
  description = "DBに適用するsecurity-groupのID"
  type        = string
}

variable "subnet_ids" {
  description = "clusterのinstanceを配置するsubnetのIDリスト。(private_subnet推奨)"
  type        = list(string)
}

variable "availability_zones" {
  description = "clusterのinstanceを分散させたいazのリスト"
  type        = list(string)
}

variable "ssm_db_password_name" {
  description = "設定したいDBのパスワードが格納されているparameter storeのname"
  type        = string
  sensitive   = true
}

variable "ssm_db_username_name" {
  description = "設定したいDBのusernameが格納されているparameter storeのname"
  type        = string
  sensitive   = true
}
