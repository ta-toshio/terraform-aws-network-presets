output "cluster_id" {
  description = "ECSクラスターID"
  value       = aws_ecs_cluster.main.id
}

output "cluster_name" {
  description = "ECSクラスター名"
  value       = aws_ecs_cluster.main.name
}

output "cluster_arn" {
  description = "作成されたECSクラスターのARN"
  value       = aws_ecs_cluster.main.arn
}

output "web_task_definition_arn" {
  description = "WebサービスのタスクARN"
  value       = aws_ecs_task_definition.web.arn
}

output "web_task_definition_family" {
  description = "WebサービスのタスクDefinitionファミリー"
  value       = aws_ecs_task_definition.web.family
}

output "cli_task_definition_arn" {
  description = "CLIコマンドのタスクARN"
  value       = aws_ecs_task_definition.cli.arn
}

output "web_service_id" {
  description = "作成されたWebサービスのID"
  value       = aws_ecs_service.web.id
}

output "web_service_name" {
  description = "Webサービス名"
  value       = aws_ecs_service.web.name
}

output "web_service_public_ip" {
  description = "Webサービスのパブリック IP (ALBなし構成用・Lambda関数で自動更新)"
  value       = var.assign_public_ip && !var.use_alb ? "動的IPアドレス（Lambda関数で自動更新）" : null
}

output "lambda_function_name" {
  description = "Route53更新用Lambda関数名（ALBなし構成用）"
  value       = var.assign_public_ip && !var.use_alb && var.route53_zone_id != null ? aws_lambda_function.update_route53[0].function_name : null
}

output "task_execution_role_arn" {
  description = "ECSタスク実行ロールARN"
  value       = aws_iam_role.task_execution_role.arn
}

output "task_role_arn" {
  description = "ECSタスクロールARN"
  value       = aws_iam_role.task_role.arn
}

output "web_log_group_name" {
  description = "Webサービスのロググループ名"
  value       = aws_cloudwatch_log_group.web.name
}

output "web_log_group_arn" {
  description = "Webサービスのロググループ ARN"
  value       = aws_cloudwatch_log_group.web.arn
}

output "cli_log_group_name" {
  description = "CLIサービスのロググループ名"
  value       = aws_cloudwatch_log_group.cli.name
}

output "cli_log_group_arn" {
  description = "CLIサービスのログループARN"
  value       = aws_cloudwatch_log_group.cli.arn
} 