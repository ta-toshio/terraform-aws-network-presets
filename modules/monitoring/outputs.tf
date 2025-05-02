output "sns_topic_arn" {
  description = "アラート通知用SNSトピックのARN"
  value       = aws_sns_topic.alerts.arn
}

output "dashboard_name" {
  description = "CloudWatchダッシュボードの名前"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "ecs_cpu_alarm_arn" {
  description = "ECS CPU使用率アラームのARN"
  value       = aws_cloudwatch_metric_alarm.ecs_cpu.arn
}

output "ecs_memory_alarm_arn" {
  description = "ECSメモリ使用率アラームのARN"
  value       = aws_cloudwatch_metric_alarm.ecs_memory.arn
}

output "error_alarm_arn" {
  description = "エラーログアラームのARN"
  value       = aws_cloudwatch_metric_alarm.error_alarm.arn
} 