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
    bucket               = "tf-state-myproject-setup"
    key                  = "tf-state-setup"
    region               = "ap-northeast-1"
    encrypt              = true
    dynamodb_table       = "tf-lock-myproject-setup"
  }
}

locals {
  terraform_state_bucket = "tf-state-myproject-setup"
  terraform_lock_table   = "tf-lock-myproject-setup"
}

# ローカルで管理してないので本来はいらないはず
# S3バケットの作成（Terraform状態管理用）
resource "aws_s3_bucket" "terraform_state" {
  bucket = local.terraform_state_bucket

  tags = {
    Service     = var.project_name
    Environment = "all"
    Managed     = "Terraform"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# DynamoDBテーブル（ステートのロック用）
resource "aws_dynamodb_table" "terraform_locks" {
  name         = local.terraform_lock_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Service     = var.project_name
    Environment = "all"
    Managed     = "Terraform"
  }
}

# IAMモジュールの呼び出し - デプロイ用IAMユーザーとポリシーを作成
module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
}

# ECRモジュールの呼び出し - 環境ごとのECRリポジトリを作成
module "ecr" {
  source = "./modules/ecr"

  project_name = var.project_name
  environments = var.environments
}
