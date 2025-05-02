# Route53モジュール - ドメイン関連の設定を一元管理

# ローカル変数で条件を設定
locals {
  # フロントエンド: Amplifyが担当
  # バックエンドAPI: ALBが担当（apiサブドメイン）
  
  # Amplifyレコード作成条件 - Amplifyが有効な場合
  create_amplify_records = var.use_amplify
  
  # ALBレコード作成条件 - ALBが有効な場合（APIサブドメインのみ）
  create_alb_api_records = var.use_alb
  
  # ECS直接アクセス用レコード作成条件 - ALBが無効でECS直接アクセスが有効な場合
  create_ecs_records = !var.use_alb && var.use_ecs_direct
  
  # レコード作成を制御するフラグ - この値をtrueにするとDNSレコードを作成する
  allow_record_creation = true
}

# ALB用Aレコード - APIサブドメイン専用
resource "aws_route53_record" "api" {
  count   = local.create_alb_api_records && local.allow_record_creation ? 1 : 0
  zone_id = var.zone_id
  name    = "api.${var.domain_name}"
  type    = "A"
  
  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

# # Amplify用CNAMEレコード - メインドメイン
# resource "aws_route53_record" "amplify" {
#   count   = local.create_amplify_records && local.use_clerk ? 1 : 0
#   zone_id = var.zone_id
#   name    = var.domain_name
#   type    = "CNAME"
#   ttl     = 300
#   records = [var.amplify_domain]
  
#   lifecycle {
#     create_before_destroy = true
#   }
# }

# # Amplify用CNAMEレコード - wwwサブドメイン
# resource "aws_route53_record" "amplify_www" {
#   count   = local.create_amplify_records && local.use_clerk ? 1 : 0
#   zone_id = var.zone_id
#   name    = "www.${var.domain_name}"
#   type    = "CNAME"
#   ttl     = 300
#   records = [var.amplify_domain]
  
#   lifecycle {
#     create_before_destroy = true
#   }
# }

# ECS直接アクセス用Aレコード - ALBがない場合のAPIエンドポイント
resource "aws_route53_record" "ecs_direct" {
  count   = local.create_ecs_records && local.allow_record_creation ? 1 : 0

  zone_id = var.zone_id
  name    = "api.${var.domain_name}"
  type    = "A"

  # ECSサービスの自動割り当てIPを指定
  records = [var.ecs_public_ip]
  ttl     = 60
  
  lifecycle {
    ignore_changes = [records]
  }
} 

# Clerk Frontend API
resource "aws_route53_record" "clerk_frontend_api" {
  count   = var.use_clerk ? 1 : 0
  zone_id = var.zone_id
  name    = "clerk.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = ["frontend-api.clerk.services"]
  
  lifecycle {
    create_before_destroy = true
  }
}

# Clerk Account Portal
resource "aws_route53_record" "clerk_accounts" {
  count   = var.use_clerk ? 1 : 0
  zone_id = var.zone_id
  name    = "accounts.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = ["accounts.clerk.services"]
  
  lifecycle {
    create_before_destroy = true
  }
}

# Clerk Email - DKIM 1
resource "aws_route53_record" "clerk_dkim1" {
  count   = var.use_clerk ? 1 : 0
  zone_id = var.zone_id
  name    = "clk._domainkey.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = ["dkim1.ntevxdnj6efu.clerk.services"]
  
  lifecycle {
    create_before_destroy = true
  }
}

# Clerk Email - DKIM 2
resource "aws_route53_record" "clerk_dkim2" {
  count   = var.use_clerk ? 1 : 0
  zone_id = var.zone_id
  name    = "clk2._domainkey.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = ["dkim2.ntevxdnj6efu.clerk.services"]
  
  lifecycle {
    create_before_destroy = true
  }
}

# Clerk Email - Mail
resource "aws_route53_record" "clerk_mail" {
  count   = var.use_clerk ? 1 : 0
  zone_id = var.zone_id
  name    = "clkmail.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = ["mail.ntevxdnj6efu.clerk.services"]
  
  lifecycle {
    create_before_destroy = true
  }
} 
