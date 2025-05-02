variable "project" {
  description = "プロジェクト名"
  type        = string
}

variable "environment" {
  description = "環境名 (dev, prod, etc.)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "RDSを配置するサブネットIDのリスト"
  type        = list(string)
}

variable "db_name" {
  description = "データベース名"
  type        = string
}

variable "db_username" {
  description = "データベースユーザー名"
  type        = string
}

variable "db_password" {
  description = "データベースパスワード"
  type        = string
  sensitive   = true
}

variable "allocated_storage" {
  description = "割り当てるストレージ容量（GB）"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "自動スケーリング時の最大ストレージ容量（GB）"
  type        = number
  default     = 100
}

variable "db_instance_class" {
  description = "RDSインスタンスタイプ"
  type        = string
  default     = "db.t3.micro"
}

variable "backup_retention_period" {
  description = "バックアップ保持期間（日数）"
  type        = number
  default     = 7
}

variable "sns_topic_arn" {
  description = "アラート通知用SNSトピックARN"
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "削除保護の有効化"
  type        = bool
  default     = false
}

# variable "web_security_group_id" {
#   description = "Webアプリケーション用セキュリティグループID"
#   type        = string
#   default     = null
# }

# variable "cli_security_group_id" {
#   description = "CLIタスク用セキュリティグループID"
#   type        = string
#   default     = null
# } 