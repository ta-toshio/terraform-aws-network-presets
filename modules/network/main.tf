# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Name        = "${var.project}-vpc"
    Environment = var.environment
  }
}

# インターネットゲートウェイ
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name        = "${var.project}-igw"
    Environment = var.environment
  }
}

# パブリックサブネット
resource "aws_subnet" "public" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 1)
  availability_zone = var.availability_zones[count.index]
  
  # パブリックIPを自動割り当て
  map_public_ip_on_launch = true
  
  tags = {
    Name        = "${var.project}-public-subnet-${count.index + 1}"
    Environment = var.environment
  }
}

# プライベートサブネット（データ層用）
resource "aws_subnet" "private" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 5)
  availability_zone = var.availability_zones[count.index]
  
  tags = {
    Name        = "${var.project}-private-subnet-${count.index + 1}"
    Environment = var.environment
  }
}

# NATゲートウェイ（条件付き）
resource "aws_eip" "nat" {
   count = var.enable_nat_gateway ? 1 : 0
   domain = "vpc" # deprecatedなvpc引数の代わりにdomainを使用
   
   tags = {
     Name        = "${var.project}-nat-eip"
     Environment = var.environment
   }
}

resource "aws_nat_gateway" "main" {
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id
  
  tags = {
    Name        = "${var.project}-nat-gateway"
    Environment = var.environment
  }
  
  depends_on = [aws_internet_gateway.main]
}

# パブリックルートテーブル
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = {
    Name        = "${var.project}-public-rt"
    Environment = var.environment
  }
}

# プライベートルートテーブル
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }
  
  tags = {
    Name        = "${var.project}-private-rt"
    Environment = var.environment
  }
}

# パブリックサブネットのルートテーブル関連付け
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# プライベートサブネットのルートテーブル関連付け
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# 現在のリージョンを取得
data "aws_region" "current" {}

# VPCエンドポイント用のセキュリティグループ
resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.project}-${var.environment}-vpc-endpoints-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Allow HTTPS from VPC"
  }

  tags = {
    Name        = "${var.project}-vpc-endpoints-sg"
    Environment = var.environment
  }
}

# S3ゲートウェイエンドポイント（無料）
resource "aws_vpc_endpoint" "s3" {
  count        = var.enable_nat_gateway || var.use_public_subnet ? 0 : 1
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
  
  route_table_ids = [
    aws_route_table.public.id,
    aws_route_table.private.id
  ]
  
  tags = {
    Name        = "${var.project}-s3-endpoint"
    Environment = var.environment
  }
}

# DynamoDBゲートウェイエンドポイント（無料）
resource "aws_vpc_endpoint" "dynamodb" {
  count        = var.enable_nat_gateway || var.use_public_subnet ? 0 : 1
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
  
  route_table_ids = [
    aws_route_table.public.id,
    aws_route_table.private.id
  ]
  
  tags = {
    Name        = "${var.project}-dynamodb-endpoint"
    Environment = var.environment
  }
}

# ECRのエンドポイント（API）
resource "aws_vpc_endpoint" "ecr_api" {
  count               = var.enable_nat_gateway || var.use_public_subnet ? 0 : 1
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
  
  tags = {
    Name        = "${var.project}-ecr-api-endpoint"
    Environment = var.environment
  }
}

# ECRのエンドポイント（Docker）
resource "aws_vpc_endpoint" "ecr_dkr" {
  count               = var.enable_nat_gateway || var.use_public_subnet ? 0 : 1
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
  
  tags = {
    Name        = "${var.project}-ecr-dkr-endpoint"
    Environment = var.environment
  }
}

# CloudWatch Logsのエンドポイント
resource "aws_vpc_endpoint" "logs" {
  count               = var.enable_nat_gateway || var.use_public_subnet ? 0 : 1
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
  
  tags = {
    Name        = "${var.project}-logs-endpoint"
    Environment = var.environment
  }
}

# 利用するとき有効化
# # SSMのエンドポイント
# resource "aws_vpc_endpoint" "ssm" {
#   count               = var.enable_nat_gateway || var.use_public_subnet ? 0 : 1
#   vpc_id              = aws_vpc.main.id
#   service_name        = "com.amazonaws.${data.aws_region.current.name}.ssm"
#   vpc_endpoint_type   = "Interface"
#   subnet_ids          = aws_subnet.private[*].id
#   security_group_ids  = [aws_security_group.vpc_endpoints.id]
#   private_dns_enabled = true
  
#   tags = {
#     Name        = "${var.project}-ssm-endpoint"
#     Environment = var.environment
#   }
# }

# # SSM Messagesのエンドポイント
# resource "aws_vpc_endpoint" "ssm_messages" {
#   count               = var.enable_nat_gateway || var.use_public_subnet ? 0 : 1
#   vpc_id              = aws_vpc.main.id
#   service_name        = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
#   vpc_endpoint_type   = "Interface"
#   subnet_ids          = aws_subnet.private[*].id
#   security_group_ids  = [aws_security_group.vpc_endpoints.id]
#   private_dns_enabled = true
  
#   tags = {
#     Name        = "${var.project}-ssm-messages-endpoint"
#     Environment = var.environment
#   }
# }

# 必要なとき有効化
# # Systems Manager用のEC2 Messagesエンドポイント
# resource "aws_vpc_endpoint" "ec2_messages" {
#   count               = var.enable_nat_gateway || var.use_public_subnet ? 0 : 1
#   vpc_id              = aws_vpc.main.id
#   service_name        = "com.amazonaws.${data.aws_region.current.name}.ec2messages"
#   vpc_endpoint_type   = "Interface"
#   subnet_ids          = aws_subnet.private[*].id
#   security_group_ids  = [aws_security_group.vpc_endpoints.id]
#   private_dns_enabled = true
  
#   tags = {
#     Name        = "${var.project}-ec2-messages-endpoint"
#     Environment = var.environment
#   }
# }

# # Secrets Managerのエンドポイント
# resource "aws_vpc_endpoint" "secretsmanager" {
#   count               = var.enable_nat_gateway || var.use_public_subnet ? 0 : 1
#   vpc_id              = aws_vpc.main.id
#   service_name        = "com.amazonaws.${data.aws_region.current.name}.secretsmanager"
#   vpc_endpoint_type   = "Interface"
#   subnet_ids          = aws_subnet.private[*].id
#   security_group_ids  = [aws_security_group.vpc_endpoints.id]
#   private_dns_enabled = true
  
#   tags = {
#     Name        = "${var.project}-secretsmanager-endpoint"
#     Environment = var.environment
#   }
# } 
