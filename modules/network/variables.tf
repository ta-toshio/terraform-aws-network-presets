variable "region" {
  description = "AWSリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "environment" {
  description = "環境（dev, prod など）"
  type        = string
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

variable "availability_zones" {
  description = "利用するアベイラビリティゾーン"
  type        = list(string)
  default     = ["ap-northeast-1a", "ap-northeast-1c"]
}

variable "use_public_subnet" {
  description = "パブリックサブネットを利用するかどうか"
  type        = bool
  default     = false
} 

variable "enable_nat_gateway" {
  description = "NATゲートウェイを有効にするかどうか"
  type        = bool
  default     = false
} 