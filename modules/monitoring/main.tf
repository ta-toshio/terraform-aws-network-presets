# SNSトピック（アラート通知用）
resource "aws_sns_topic" "alerts" {
  name = "${var.project}-${var.environment}-alerts"
  
  tags = {
    Name        = "${var.project}-${var.environment}-alerts"
    Environment = var.environment
  }
}

# ECS CPU使用率アラーム
resource "aws_cloudwatch_metric_alarm" "ecs_cpu" {
  alarm_name          = "${var.project}-${var.environment}-ecs-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "ECS CPU使用率が85%を超過"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  
  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }
  
  tags = {
    Name        = "${var.project}-${var.environment}-ecs-cpu-alarm"
    Environment = var.environment
  }
}

# メモリ使用率アラーム
resource "aws_cloudwatch_metric_alarm" "ecs_memory" {
  alarm_name          = "${var.project}-${var.environment}-ecs-memory-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "ECSメモリ使用率が85%を超過"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  
  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }
  
  tags = {
    Name        = "${var.project}-${var.environment}-ecs-memory-alarm"
    Environment = var.environment
  }
}

# ダッシュボード
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project}-${var.environment}-dashboard"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", var.ecs_cluster_name, "ServiceName", var.ecs_service_name]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "ECS CPU使用率"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "MemoryUtilization", "ClusterName", var.ecs_cluster_name, "ServiceName", var.ecs_service_name]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "ECSメモリ使用率"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.rds_instance_id]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "RDS CPU使用率"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", var.rds_instance_id]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "RDS空き容量"
        }
      }
    ]
  })
}

# CloudWatchログフィルター
resource "aws_cloudwatch_log_metric_filter" "error_filter" {
  name           = "${var.project}-${var.environment}-error-filter"
  pattern        = "ERROR"
  log_group_name = var.ecs_log_group_name
  
  metric_transformation {
    name      = "${var.project}ErrorCount"
    namespace = "${var.project}/${var.environment}/Application"
    value     = "1"
  }
}

# エラーログに基づくアラーム
resource "aws_cloudwatch_metric_alarm" "error_alarm" {
  alarm_name          = "${var.project}-${var.environment}-error-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "${var.project}ErrorCount"
  namespace           = "${var.project}/${var.environment}/Application"
  period              = 60
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "アプリケーションログでエラーが5回以上検出されました"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  
  tags = {
    Name        = "${var.project}-${var.environment}-error-alarm"
    Environment = var.environment
  }
}

# 現在のリージョンを取得
data "aws_region" "current" {} 