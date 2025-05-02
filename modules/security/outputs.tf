output "web_direct_sg_id" {
  description = "Webサーバー用セキュリティグループID（ALB未使用時）"
  value       = aws_security_group.web_direct.id
}

output "cli_sg_id" {
  description = "CLIコマンド用セキュリティグループID"
  value       = aws_security_group.cli.id
} 