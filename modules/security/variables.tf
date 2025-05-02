variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "project" {
  description = "プロジェクト名"
  type        = string
}

variable "environment" {
  description = "環境名 (dev, prod, etc.)"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWSリージョン"
  type        = string
  default     = "ap-northeast-1"
} 