output "db_endpoint" {
  description = "RDS DBインスタンスのエンドポイント"
  value       = module.rds.db_endpoint
}

output "db_name" {
  description = "RDS DBインスタンスのエンドポイント"
  value       = module.rds.db_name
}

output "db_username" {
  description = "RDS DBインスタンスのエンドポイント"
  value       = module.rds.db_username
}

output "cli_sg_id" {
  description = "ECS CLIセキュリティグループID"
  value       = module.security.cli_sg_id
}

output "ecs_cli_subnet" {
  description = "ECS CLIサブネットID"
  value       = module.network.private_app_subnet_ids
}
