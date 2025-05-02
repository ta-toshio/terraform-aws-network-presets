variable "domain_name" {
  description = "サービスのドメイン名"
  type        = string
}

variable "route53_zone_id" {
  description = "Route53のホストゾーンID"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "パブリックサブネットのID"
  type        = list(string)
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