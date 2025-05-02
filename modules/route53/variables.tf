variable "project" {
  description = "プロジェクト名"
  type        = string
}

variable "environment" {
  description = "環境（dev, prod など）"
  type        = string
}

variable "zone_id" {
  description = "Route53ゾーンID"
  type        = string
}

variable "base_domain_name" {
  description = "ベースドメイン名（example.com）"
  type        = string
}

variable "domain_name" {
  description = "使用するドメイン名（dev.example.com など）"
  type        = string
}

# ALB関連
variable "use_alb" {
  description = "ALBを使用するかどうか"
  type        = bool
  default     = false
}

variable "alb_dns_name" {
  description = "ALBのDNS名"
  type        = string
  default     = null
}

variable "alb_zone_id" {
  description = "ALBのゾーンID"
  type        = string
  default     = null
}

# Amplify関連
variable "use_amplify" {
  description = "Amplifyを使用するかどうか"
  type        = bool
  default     = false
}

variable "amplify_domain" {
  description = "Amplifyアプリのデフォルトドメイン"
  type        = string
  default     = null
}

# ECS関連
variable "use_ecs_direct" {
  description = "ECS直接アクセスを使用するかどうか"
  type        = bool
  default     = false
}

variable "ecs_public_ip" {
  description = "ECSサービスのパブリックIP"
  type        = string
  default     = "127.0.0.1"  # 初期値
} 

# Clerk関連
variable "use_clerk" {
  description = "clerk DNSを設定するかどうか"
  type        = bool
  default     = false
}