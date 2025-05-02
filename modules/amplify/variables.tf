variable "project" {
  description = "プロジェクト名"
  type        = string
}

variable "environment" {
  description = "環境（dev, prod など）"
  type        = string
}

variable "domain_name" {
  description = "サービスのドメイン名"
  type        = string
}

variable "repository_url" {
  description = "GitHubリポジトリURL"
  type        = string
}

variable "oauth_token" {
  description = "GitHubのOAuthトークン"
  type        = string
  sensitive   = true
}

variable "branch_name" {
  description = "デプロイするブランチ名"
  type        = string
  default     = "main"
} 

variable "app_root" {
  description = "アプリケーションのルートディレクトリ"
  type        = string
  default     = "web"
}
