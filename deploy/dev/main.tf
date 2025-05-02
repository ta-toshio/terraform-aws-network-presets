provider "aws" {
  region = var.region
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket               = "tf-state-myproject-dev"
    key                  = "tf-state-deploy"
    workspace_key_prefix = "tf-state-deploy-env"
    region               = "ap-northeast-1"
    encrypt              = true
    dynamodb_table       = "tf-lock-myproject-dev"
  }
}

# ワークスペース設定マトリックス
locals {
  config = {
    "public-with-alb" = {
      use_public_subnet  = true
      use_alb            = true
      enable_nat_gateway = false
    }
    "public-no-alb" = {
      use_public_subnet  = true
      use_alb            = false
      enable_nat_gateway = false
    }
    "private-with-alb" = {
      use_public_subnet  = false
      use_alb            = true
      enable_nat_gateway = true
    }
    "private-no-alb" = {
      use_public_subnet  = false
      use_alb            = false
      enable_nat_gateway = true
    }
  }

  # 現在のワークスペース設定を取得（開発環境ではコスト削減のためALBなしをデフォルトに）
  current_config = lookup(local.config, terraform.workspace, local.config["public-no-alb"])

  # 設定を適用
  use_public_subnet  = local.current_config.use_public_subnet
  use_alb            = local.current_config.use_alb
  enable_nat_gateway = local.current_config.enable_nat_gateway

  # 開発環境のリソース設定
  environment = "dev"
  domain_name = "dev.${var.base_domain_name}"

  # 開発環境向けのリソースサイズ設定
  instance_type = "db.t3.micro"
  min_capacity  = 1
  max_capacity  = 1
}

# ネットワークモジュール
module "network" {
  source = "../../modules/network"

  project     = var.project
  environment = local.environment
  vpc_cidr    = var.vpc_cidr

  enable_nat_gateway = local.enable_nat_gateway
  use_public_subnet  = local.use_public_subnet
}

# セキュリティモジュール
module "security" {
  source = "../../modules/security"

  project     = var.project
  environment = local.environment
  vpc_id      = module.network.vpc_id
}


# AWS Route53ゾーンデータソース
data "aws_route53_zone" "zone" {
  name = "${var.base_domain_name}."
}

# ALBモジュール（条件付き）
module "alb" {
  count  = local.use_alb ? 1 : 0
  source = "../../modules/alb"

  project           = var.project
  environment       = local.environment
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  domain_name       = local.domain_name
  route53_zone_id   = data.aws_route53_zone.zone.zone_id
}


# RDSモジュール
module "rds" {
  source = "../../modules/rds"

  project     = var.project
  environment = local.environment
  vpc_id      = module.network.vpc_id

  # プライベートサブネットに配置
  subnet_ids = module.network.private_app_subnet_ids

  # データベース設定
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password

  # 開発用DBインスタンスタイプ（最小構成）
  db_instance_class = local.instance_type

  # モニタリング
  sns_topic_arn = module.monitoring.sns_topic_arn

  # 開発環境では削除保護を無効化する
  deletion_protection = false
}


# ECSモジュール
module "ecs" {
  source = "../../modules/ecs"

  project     = var.project
  environment = local.environment
  vpc_id      = module.network.vpc_id
  region      = var.region

  # サブネット選択
  subnet_ids = local.use_public_subnet ? module.network.public_subnet_ids : module.network.private_app_subnet_ids

  # セキュリティグループ選択（ALBの有無で変更）
  web_security_group_id = local.use_alb ? module.alb[0].web_with_alb_sg_id : module.security.web_direct_sg_id
  cli_security_group_id = module.security.cli_sg_id

  # ALB設定（ALB使用時のみ）
  use_alb          = local.use_alb
  target_group_arn = local.use_alb ? module.alb[0].target_group_arn : null

  # パブリックIP割り当て（パブリックサブネット使用時のみ）
  assign_public_ip = local.use_public_subnet

  # Route53設定（ALBなし構成用）
  route53_zone_id = local.use_alb ? null : data.aws_route53_zone.zone.zone_id
  domain_name     = local.use_alb ? null : local.domain_name

  # コンテナイメージ 
  web_image = var.ecr_repo_web_uri
  cli_image = var.ecr_repo_cli_uri

  # Auto Scaling - 開発環境用設定（スケーリングなし）
  enable_autoscaling = false
  min_capacity       = local.min_capacity
  max_capacity       = local.max_capacity

  # アプリケーション環境
  app_env = var.app_env

  # データベース接続情報
  db_host     = split(":", module.rds.db_endpoint)[0] # エンドポイントからホスト部分のみを取得
  db_type     = var.db_type
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password
  db_port     = var.db_port
  db_ssl_mode = var.db_ssl_mode

  # APIコンテナ
  container_port = var.api_container_port
}

# モニタリングモジュール
module "monitoring" {
  source = "../../modules/monitoring"

  project     = var.project
  environment = local.environment
  alert_email = var.alert_email

  ecs_cluster_name   = module.ecs.cluster_name
  ecs_service_name   = module.ecs.web_service_name
  ecs_log_group_name = module.ecs.web_log_group_name
  rds_instance_id    = module.rds.db_instance_id
}

# 段階的に復元 - まずAmplifyだけ
# Amplifyモジュール
module "amplify" {
  source = "../../modules/amplify"

  project     = var.project
  environment = local.environment
  domain_name = local.domain_name

  # リポジトリ設定はコメントアウトしたまま（Amplifyモジュールでは無効化済み）
  repository_url = var.amplify_repository_url
  oauth_token    = var.amplify_oauth_token
  branch_name    = "develop" # 開発環境用のブランチ名
  app_root       = "web"     # アプリケーションのルートディレクトリを指定

}

# Route53モジュール
module "route53" {
  source = "../../modules/route53"

  project          = var.project
  environment      = local.environment
  zone_id          = data.aws_route53_zone.zone.zone_id
  base_domain_name = var.base_domain_name
  domain_name      = local.domain_name

  # ALB関連設定
  use_alb = local.use_alb
  # ALBがない場合は null を設定
  alb_dns_name = local.use_alb ? module.alb[0].alb_dns_name : null
  alb_zone_id  = local.use_alb ? module.alb[0].alb_zone_id : null

  # Amplify関連設定
  use_amplify    = true # Amplifyは常に有効
  amplify_domain = module.amplify.default_domain

  # ECS直接アクセス関連設定（ALBなしの場合）
  use_ecs_direct = !local.use_alb
  # ecs_public_ipはLambda関数によって動的に更新されるため、初期値のままでOK

  # Amplifyドメイン連携のため、明示的に依存関係を設定
  depends_on = [module.amplify]
}

# RDSセキュリティグループにECS関連のセキュリティグループを追加するコードも追加します
resource "aws_security_group_rule" "rds_ingress_from_ecs" {
  security_group_id        = module.rds.db_sg_id
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = local.use_alb ? module.alb[0].web_with_alb_sg_id : module.security.web_direct_sg_id
  description              = "PostgreSQL access from ECS web tasks"
}

resource "aws_security_group_rule" "rds_ingress_from_cli" {
  security_group_id        = module.rds.db_sg_id
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = module.security.cli_sg_id
  description              = "PostgreSQL access from ECS CLI tasks"
}
