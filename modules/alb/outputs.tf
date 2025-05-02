output "alb_id" {
  description = "ALB ID"
  value       = aws_lb.main.id
}

output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "ALBのDNS名"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "ALBのRoute53 Zone ID"
  value       = aws_lb.main.zone_id
}

output "target_group_arn" {
  description = "ターゲットグループARN"
  value       = aws_lb_target_group.main.arn
}

output "certificate_arn" {
  description = "ACM証明書ARN"
  value       = aws_acm_certificate.main.arn
}

output "alb_sg_id" {
  description = "ALB用セキュリティグループID"
  value       = aws_security_group.alb.id
}

output "web_with_alb_sg_id" {
  description = "Webサーバー用セキュリティグループID（ALB使用時）"
  value       = aws_security_group.web_with_alb.id
} 