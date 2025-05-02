output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "パブリックサブネットIDのリスト"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "プライベートサブネットIDのリスト"
  value       = aws_subnet.private[*].id
}

output "private_app_subnet_ids" {
  description = "プライベートアプリケーションサブネットIDのリスト（public-no-alb構成でのルーティング用）"
  value       = aws_subnet.private[*].id
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  # NATゲートウェイは削除されたため、常にnullを返す
  value       = var.enable_nat_gateway ? aws_nat_gateway.main[0].id : null
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.main.id
}

output "s3_vpc_endpoint_id" {
  description = "S3 VPC Endpoint ID"
  value       = var.enable_nat_gateway || var.use_public_subnet ? null : aws_vpc_endpoint.s3[0].id
}

output "dynamodb_vpc_endpoint_id" {
  description = "DynamoDB VPC Endpoint ID"
  value       = var.enable_nat_gateway || var.use_public_subnet ? null : aws_vpc_endpoint.dynamodb[0].id
}

output "ecr_api_vpc_endpoint_id" {
  description = "ECR API VPC Endpoint ID"
  value       = var.enable_nat_gateway || var.use_public_subnet ? null : aws_vpc_endpoint.ecr_api[0].id
}

output "ecr_dkr_vpc_endpoint_id" {
  description = "ECR Docker VPC Endpoint ID"
  value       = var.enable_nat_gateway || var.use_public_subnet ? null : aws_vpc_endpoint.ecr_dkr[0].id
}

output "logs_vpc_endpoint_id" {
  description = "CloudWatch Logs VPC Endpoint ID"
  value       = var.enable_nat_gateway || var.use_public_subnet ? null : aws_vpc_endpoint.logs[0].id
}

# output "ssm_vpc_endpoint_id" {
#   description = "SSM VPC Endpoint ID"
#   value       = var.enable_nat_gateway ? null : aws_vpc_endpoint[0].ssm.id
# }

output "vpc_endpoints_security_group_id" {
  description = "VPCエンドポイント用セキュリティグループID"
  value       = aws_security_group.vpc_endpoints.id
} 
