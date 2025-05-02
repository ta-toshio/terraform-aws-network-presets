variable "region" {
  description = "AWSリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "project" {
  description = "プロジェクト名"
  type        = string
}

variable "vpc_cidr" {
  description = "VPCのCIDRブロック"
  type        = string
  default     = "10.0.0.0/16"
}

variable "base_domain_name" {
  description = "ベースドメイン名"
  type        = string
}

variable "web_min_capacity" {
  description = "Webサービスの最小容量"
  type        = number
  default     = 1
}

variable "web_max_capacity" {
  description = "Webサービスの最大容量"
  type        = number
  default     = 1
}

variable "db_instance_type" {
  description = "データベースインスタンスタイプ"
  type        = string
  default     = "db.t3.micro"
}


# ecr関連
variable "ecr_repo_web_uri" {
  description = "Webサービス用のコンテナイメージ"
  type        = string
}

variable "ecr_repo_cli_uri" {
  description = "CLIサービス用のコンテナイメージ"
  type        = string
}

variable "amplify_repository_url" {
  description = "AmplifyのリポジトリURL"
  type        = string
}

# ecs関連
variable "api_container_port" {
  description = "APIコンテナのポート番号"
  type        = number
  default     = 8080
}

# amplify関連
variable "amplify_oauth_token" {
  description = "Amplifyのリポジトリアクセス用OAuthトークン"
  type        = string
  sensitive   = true
}

# RDS関連の変数
variable "db_type" {
  description = "データベースタイプ"
  type        = string
  default     = "postgres"
}

variable "db_name" {
  description = "データベース名"
  type        = string
}

variable "db_username" {
  description = "データベースのマスターユーザー名"
  type        = string
}

variable "db_password" {
  description = "データベースのマスターパスワード"
  type        = string
  sensitive   = true
}

variable "db_port" {
  description = "データベースポート番号"
  type        = number
  default     = 5432
}

variable "db_ssl_mode" {
  description = "データベースSSLモード"
  type        = string
  default     = "require"
}

# モニタリング関連の変数
variable "alert_email" {
  description = "アラート通知先のメールアドレス"
  type        = string
}

# アプリケーション環境
variable "app_env" {
  description = "アプリケーション環境"
  type        = string
}
