# ALB用セキュリティグループ
resource "aws_security_group" "alb" {
  name        = "${var.project}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access from internet"
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access from internet"
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
  
  tags = {
    Name        = "${var.project}-alb-sg"
    Environment = var.environment
  }
}

# Webサーバー用セキュリティグループ (ALB使用時)
resource "aws_security_group" "web_with_alb" {
  name        = "${var.project}-web-with-alb-sg"
  description = "Security group for web server (ECS Fargate) with ALB"
  vpc_id      = var.vpc_id
  
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "Access from ALB only"
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
  
  tags = {
    Name        = "${var.project}-web-with-alb-sg"
    Environment = var.environment
  }
}

# ACM証明書
resource "aws_acm_certificate" "main" {
  # APIサブドメインのみを対象にする
  domain_name       = "api.${var.domain_name}"
  validation_method = "DNS"
  
  # メインドメインはAmplifyが使用するため、代替名は不要
  # subject_alternative_names = ["www.${var.domain_name}"]
  
  tags = {
    Name        = "${var.project}-api-certificate"
    Environment = var.environment
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

# Route53でのDNS検証レコード
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  
  name            = each.value.name
  records         = [each.value.record]
  type            = each.value.type
  zone_id         = var.route53_zone_id
  ttl             = 60
  allow_overwrite = true
}

# 証明書の検証完了を待機
resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# ALB
resource "aws_lb" "main" {
  name               = "${var.project}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids
  
  enable_deletion_protection = false # テスト環境では無効
  
  tags = {
    Name        = "${var.project}-alb"
    Environment = var.environment
  }
}

# HTTPSリスナー
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.main.arn
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
  
  depends_on = [aws_acm_certificate_validation.main]
}

# HTTPリスナー (HTTPSにリダイレクト)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"
  
  default_action {
    type = "redirect"
    
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ターゲットグループ
resource "aws_lb_target_group" "main" {
  name        = "${var.project}-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  
  health_check {
    enabled             = true
    interval            = 30
    path                = "/health"
    port                = "traffic-port"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
  
  tags = {
    Name        = "${var.project}-tg"
    Environment = var.environment
  }
}

# Route53レコード - Route53モジュールに移行しました
# ALBでのRoute53レコード作成はなくなりました