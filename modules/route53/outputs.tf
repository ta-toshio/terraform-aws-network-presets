output "zone_id" {
  description = "Route53ゾーンID"
  value       = var.zone_id
}

output "domain_name" {
  description = "設定されたドメイン名"
  value       = var.domain_name
}

output "api_record_name" {
  description = "API向けのRoute53レコード名"
  value       = local.create_alb_api_records && length(aws_route53_record.api) > 0 ? aws_route53_record.api[0].name : null
}

# output "amplify_record_name" {
#   description = "Amplify向けのRoute53レコード名"
#   value       = local.create_amplify_records && length(aws_route53_record.amplify) > 0 ? aws_route53_record.amplify[0].name : null
# }

# output "amplify_www_record_name" {
#   description = "Amplify向けのwwwサブドメインレコード名"
#   value       = local.create_amplify_records && length(aws_route53_record.amplify_www) > 0 ? aws_route53_record.amplify_www[0].name : null
# }

output "ecs_direct_record_name" {
  description = "ECS直接アクセス向けのRoute53レコード名"
  value       = local.create_ecs_records && length(aws_route53_record.ecs_direct) > 0 ? aws_route53_record.ecs_direct[0].name : null
} 