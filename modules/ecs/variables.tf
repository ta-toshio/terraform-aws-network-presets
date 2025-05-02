variable "project" {
  description = "プロジェクト名"
  type        = string
}

variable "environment" {
  description = "環境（dev, prod など）"
  type        = string
}

variable "region" {
  description = "AWSリージョン"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "サブネットIDのリスト"
  type        = list(string)
}

variable "web_security_group_id" {
  description = "Webサービス用セキュリティグループID"
  type        = string
}

variable "cli_security_group_id" {
  description = "CLIコマンド用セキュリティグループID"
  type        = string
}

variable "container_port" {
  description = "コンテナのポート番号"
  type        = number
  default     = 8080
}

variable "image_tag" {
  description = "Webコンテナイメージのタグ"
  type        = string
  default     = "latest"
}

variable "cli_image_tag" {
  description = "CLIコンテナイメージのタグ"
  type        = string
  default     = "latest"
}

variable "db_type" {
  description = "データベースタイプ"
  type        = string
}

variable "db_host" {
  description = "データベースホスト"
  type        = string
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

variable "db_port" {
  description = "データベースポート番号"
  type        = number
  default     = 5432
}

variable "db_ssl_mode" {
  description = "データベースポート番号"
  type        = string
  default = "require"
}

variable "additional_environment_variables" {
  description = "コンテナに追加する環境変数"
  type        = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "use_alb" {
  description = "ALBを使用するかどうか"
  type        = bool
  default     = true
}

variable "target_group_arn" {
  description = "ALBターゲットグループARN（ALB使用時）"
  type        = string
  default     = null
}

variable "assign_public_ip" {
  description = "パブリックIPを割り当てるかどうか"
  type        = bool
  default     = true
}

variable "enable_autoscaling" {
  description = "Auto Scalingを有効にするかどうか"
  type        = bool
  default     = false
}

variable "min_capacity" {
  description = "Auto Scalingの最小容量"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Auto Scalingの最大容量"
  type        = number
  default     = 5
}

variable "web_service_desired_count" {
  description = "Webサービスの希望するタスク数"
  type        = number
  default     = 1
}

variable "web_image" {
  description = "Webサービスのコンテナイメージ"
  type        = string
}

variable "cli_image" {
  description = "CLIコマンドのコンテナイメージ"
  type        = string
}

# Lambda用のRoute53ゾーンID
variable "route53_zone_id" {
  description = "Lambda関数が更新するRoute53ホストゾーンID（ALBなし構成時のみ使用）"
  type        = string
  default     = null
}

# Lambda用のドメイン名
variable "domain_name" {
  description = "Lambda関数が更新するドメイン名（ALBなし構成時のみ使用）"
  type        = string
  default     = null
} 

variable "app_env" {
  description = "アプリケーション環境"
  type        = string
}
