# RDSデータベース用セキュリティグループ
resource "aws_security_group" "rds" {
  name        = "${var.project}-${var.environment}-rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = var.vpc_id

  # インバウンドルールはaws_security_group_ruleリソースで定義
  # 全方向からのアクセスを許可する代わりに、特定のセキュリティグループからのみアクセスを許可
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
  
  tags = {
    Name        = "${var.project}-${var.environment}-rds-sg"
    Environment = var.environment
  }
}

# planの段階では未確定のため
# # Webアプリケーションからのアクセスを許可
# resource "aws_security_group_rule" "rds_ingress_from_web" {
#   count                    = var.web_security_group_id != null ? 1 : 0
#   security_group_id        = aws_security_group.rds.id
#   type                     = "ingress"
#   from_port                = 5432
#   to_port                  = 5432
#   protocol                 = "tcp"
#   source_security_group_id = var.web_security_group_id
#   description              = "PostgreSQL access from ECS web tasks"
# }

# # CLIタスクからのアクセスを許可
# resource "aws_security_group_rule" "rds_ingress_from_cli" {
#   count                    = var.cli_security_group_id != null ? 1 : 0
#   security_group_id        = aws_security_group.rds.id
#   type                     = "ingress"
#   from_port                = 5432
#   to_port                  = 5432
#   protocol                 = "tcp"
#   source_security_group_id = var.cli_security_group_id
#   description              = "PostgreSQL access from ECS CLI tasks"
# }

# RDS用 DB サブネットグループ
resource "aws_db_subnet_group" "main" {
  name       = "${var.project}-db-subnet-group"
  subnet_ids = var.subnet_ids
  
  tags = {
    Name        = "${var.project}-db-subnet-group"
    Environment = var.environment
  }
}

# RDS PostgreSQLインスタンス
resource "aws_db_instance" "main" {
  identifier             = "${var.project}-${var.environment}-db"
  engine                 = "postgres"
  engine_version         = "17.4"
  instance_class         = var.db_instance_class
  allocated_storage      = var.allocated_storage
  max_allocated_storage  = var.max_allocated_storage
  storage_type           = "gp2"
  storage_encrypted      = true
  
  # 認証情報
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  
  # ネットワーク
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  
  # バックアップと保守
  backup_retention_period = var.backup_retention_period
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"
  
  # 高可用性（コスト削減のため無効）
  multi_az               = false
  
  # 削除保護（本番環境では有効化推奨）
  deletion_protection    = var.environment == "prod" ? true : false
  skip_final_snapshot    = var.environment == "prod" ? false : true
  final_snapshot_identifier = var.environment == "prod" ? "${var.project}-${var.environment}-final-snapshot" : null
  
  # パラメータとオプション
  parameter_group_name   = aws_db_parameter_group.main.name
  option_group_name      = aws_db_option_group.main.name
  
  # モニタリング
  monitoring_interval    = 0 # 拡張モニタリング無効（コスト削減）
  
  # パフォーマンスインサイト
  performance_insights_enabled          = false # 無効（コスト削減）
  performance_insights_retention_period = 0
  
  tags = {
    Name        = "${var.project}-${var.environment}-db"
    Environment = var.environment
  }
}

# PostgreSQL パラメータグループ
resource "aws_db_parameter_group" "main" {
  name   = "${var.project}-${var.environment}-pg-params"
  family = "postgres17"
  
  parameter {
    name  = "log_connections"
    value = "1"
  }
  
  parameter {
    name  = "log_disconnections"
    value = "1"
  }
  
  # 日本語対応
  parameter {
    name  = "client_encoding"
    value = "UTF8"
    apply_method = "immediate"
  }
  
  tags = {
    Name        = "${var.project}-${var.environment}-pg-params"
    Environment = var.environment
  }
}

# RDS オプショングループ
resource "aws_db_option_group" "main" {
  name                 = "${var.project}-${var.environment}-pg-options"
  engine_name          = "postgres"
  major_engine_version = "17"
  
  tags = {
    Name        = "${var.project}-${var.environment}-pg-options"
    Environment = var.environment
  }
}

# CloudWatch アラーム - CPU使用率
resource "aws_cloudwatch_metric_alarm" "db_cpu" {
  alarm_name          = "${var.project}-${var.environment}-db-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "RDS CPU使用率が85%を超過"
  alarm_actions       = var.sns_topic_arn != null ? [var.sns_topic_arn] : []
  ok_actions          = var.sns_topic_arn != null ? [var.sns_topic_arn] : []
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }
  
  tags = {
    Name        = "${var.project}-${var.environment}-db-cpu-alarm"
    Environment = var.environment
  }
}

# CloudWatch アラーム - 空き容量
resource "aws_cloudwatch_metric_alarm" "db_free_storage" {
  alarm_name          = "${var.project}-${var.environment}-db-storage-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.allocated_storage * 1073741824 * 0.1 # 10%の空き容量
  alarm_description   = "RDS空き容量が10%未満"
  alarm_actions       = var.sns_topic_arn != null ? [var.sns_topic_arn] : []
  ok_actions          = var.sns_topic_arn != null ? [var.sns_topic_arn] : []
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }
  
  tags = {
    Name        = "${var.project}-${var.environment}-db-storage-alarm"
    Environment = var.environment
  }
} 
