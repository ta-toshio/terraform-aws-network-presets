variable "project" {
  description = "プロジェクト名"
  type        = string
}

variable "environment" {
  description = "環境（dev, prod など）"
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECSクラスターの名前"
  type        = string
}

variable "ecs_service_name" {
  description = "Webサービスの名前"
  type        = string
}

variable "ecs_log_group_name" {
  description = "ECSロググループの名前"
  type        = string
}

variable "rds_instance_id" {
  description = "RDSインスタンスのID"
  type        = string
}

variable "alert_email" {
  description = "アラート通知先のメールアドレス"
  type        = string
  default     = null
} 