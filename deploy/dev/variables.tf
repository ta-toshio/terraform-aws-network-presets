variable "region" {
  description = "AWSのリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "project" {
  description = "プロジェクト名"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC用のCIDRブロック"
  type        = string
  default     = "10.0.0.0/16"
}

variable "base_domain_name" {
  description = "ベースドメイン名"
  type        = string
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
  description = "Amplifyリポジトリのソースコード"
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
  description = "Amplifyリポジトリアクセス用のOAuthトークン"
  type        = string
  sensitive   = true
}

# rds関連の変数
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
  description = "データベースユーザー名"
  type        = string
  default     = "dbuser"
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
  description = "データベースSSLモード"
  type        = string
  default     = "require"
}

# モニタリング関連
variable "alert_email" {
  description = "アラート通知用のメールアドレス"
  type        = string
}

# アプリケーション環境
variable "app_env" {
  description = "アプリケーション環境"
  type        = string
  default     = "development"
}
