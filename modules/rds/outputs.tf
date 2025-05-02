output "db_instance_id" {
  description = "RDBインスタンスID"
  value       = aws_db_instance.main.id
}

output "db_instance_address" {
  description = "RDSインスタンスのアドレス"
  value       = aws_db_instance.main.address
}

output "db_instance_endpoint" {
  description = "RDSインスタンスのエンドポイント"
  value       = aws_db_instance.main.endpoint
}

output "db_instance_arn" {
  description = "RDSインスタンスのARN"
  value       = aws_db_instance.main.arn
}

output "db_name" {
  description = "RDSデータベース名"
  value       = aws_db_instance.main.db_name
}

output "db_username" {
  description = "RDSデータベースユーザー名"
  value       = aws_db_instance.main.username
}

output "db_subnet_group_id" {
  description = "DBサブネットグループID"
  value       = aws_db_subnet_group.main.id
}

output "db_parameter_group_id" {
  description = "DBパラメータグループID"
  value       = aws_db_parameter_group.main.id
}

output "db_option_group_id" {
  description = "DBオプショングループID"
  value       = aws_db_option_group.main.id
}

output "db_endpoint" {
  description = "RDS DBインスタンスのエンドポイント"
  value       = aws_db_instance.main.endpoint
}

output "db_sg_id" {
  description = "RDSセキュリティグループID"
  value       = aws_security_group.rds.id
} 