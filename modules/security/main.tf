# セキュリティモジュール - 基本的なWebアプリケーション用セキュリティグループ定義

# Webサーバー用セキュリティグループ (ALB未使用時、直接アクセス)
resource "aws_security_group" "web_direct" {
  name        = "${var.project}-${var.environment}-web-direct-sg"
  description = "Security group for web server (ECS Fargate) without ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access from internet"
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access from internet"
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
  
  tags = {
    Name        = "${var.project}-${var.environment}-web-direct-sg"
    Environment = var.environment
  }
}

# CLIコマンド用セキュリティグループ
resource "aws_security_group" "cli" {
  name        = "${var.project}-${var.environment}-cli-sg"
  description = "Security group for CLI commands (ECS Fargate)"
  vpc_id      = var.vpc_id
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
  
  tags = {
    Name        = "${var.project}-${var.environment}-cli-sg"
    Environment = var.environment
  }
} 