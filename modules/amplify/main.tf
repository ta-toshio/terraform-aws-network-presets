# Amplifyアプリケーションのデプロイとホスティングリソース
resource "aws_amplify_app" "frontend" {
  name         = "${var.project}-frontend"
  
  repository   = var.repository_url
  access_token = var.oauth_token

  platform = "WEB_COMPUTE"
  
  # IAMサービスロールを設定
  iam_service_role_arn = aws_iam_role.amplify_role.arn

  lifecycle {
    create_before_destroy = false
  }
  
  # ビルド設定
  build_spec = <<-EOT
    version: 1
    applications:
      - frontend:
          phases:
            preBuild:
              commands:
                - env | grep '^target_' | sed 's/^target_//' > .env
                - npm install -g pnpm
                - pnpm install
            build:
              commands:
                - npm run build
          artifacts:
            baseDirectory: .next
            files:
              - '**/*'
          cache:
            paths:
              - .next/cache/**/*
              - .npm/**/*
        appRoot: ${var.app_root}
  EOT
  
  # 環境変数
  environment_variables = {
    AMPLIFY_MONOREPO_APP_ROOT     = var.app_root
    target_APP_ENV                = var.environment
    target_API_BASE_URL           = "https://api.${var.domain_name}"
    target_NEXT_PUBLIC_API_BASE_URL = "https://api.${var.domain_name}"
    target_NEXT_PUBLIC_APP_NAME   = var.project
  }
  
  custom_rule {
    source = "https://www.${var.domain_name}"
    status = "302"
    target = "https://${var.domain_name}"
  }

  custom_rule {
    source = "/<*>"
    status = "404"
    target = "/index.html"
  }

  tags = {
    Name        = "${var.project}-frontend"
    Environment = var.environment
  }
}

# Amplify用IAMロール
resource "aws_iam_role" "amplify_role" {
  name = "${var.project}-${var.environment}-amplify-role"
  
  # 信頼関係の設定 - Amplifyサービスがこのロールを引き受けることを許可
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = ["amplify.amazonaws.com"]
        }
      }
    ]
  })
  
  tags = {
    Name        = "${var.project}-amplify-role"
    Environment = var.environment
  }
}

# Amplify用ポリシー
resource "aws_iam_policy" "amplify_policy" {
  name        = "${var.project}-${var.environment}-amplify-policy"
  description = "Policy for AWS Amplify to access necessary resources"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.project}-*/*",
          "arn:aws:s3:::${var.project}-*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParametersByPath",
          "ssm:GetParameters",
          "ssm:GetParameter"
        ]
        Resource = "arn:aws:ssm:*:*:parameter/amplify/${var.project}/*"
      }
    ]
  })
  
  tags = {
    Name        = "${var.project}-amplify-policy"
    Environment = var.environment
  }
}

# ポリシーをロールにアタッチ
resource "aws_iam_role_policy_attachment" "amplify_policy_attachment" {
  role       = aws_iam_role.amplify_role.name
  policy_arn = aws_iam_policy.amplify_policy.arn
}

# AdministratorAccess-Amplifyポリシーをアタッチ（開発環境では便宜的に）
resource "aws_iam_role_policy_attachment" "amplify_admin_policy_attachment" {
  role       = aws_iam_role.amplify_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess-Amplify"
}

# ブランチのデプロイ設定
resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.frontend.id
  branch_name = var.branch_name
  framework = "Next.js - SSR"
  # stage     = "PRODUCTION"
  
  # 自動ビルド設定
  enable_auto_build = true
  
  # 環境変数（ブランチ固有）
  environment_variables = {
    NEXT_PUBLIC_BRANCH = var.branch_name
  }
  
  tags = {
    Name        = "${var.project}-branch-${var.branch_name}"
    Environment = var.environment
  }
}

# ドメイン設定
resource "aws_amplify_domain_association" "main" {
  app_id      = aws_amplify_app.frontend.id
  domain_name = var.domain_name
  
  # サブドメイン設定
  sub_domain {
    branch_name = aws_amplify_branch.main.branch_name
    prefix      = "www"
  }
  
  sub_domain {
    branch_name = aws_amplify_branch.main.branch_name
    prefix      = ""
  }

  # ドメイン検証を待たない
  # DNS設定はRoute53モジュールで行う
  wait_for_verification = false
}
