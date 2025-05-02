# ECSクラスターの作成
resource "aws_ecs_cluster" "main" {
  name = "${var.project}-cluster"
  
  setting {
    name  = "containerInsights"
    value = "disabled"
  }
  
  tags = {
    Name        = "${var.project}-cluster"
    Environment = var.environment
  }
}

# CloudWatch Logsグループ - Webサービス用
resource "aws_cloudwatch_log_group" "web" {
  name              = "/ecs/${var.project}-web"
  retention_in_days = 7
  
  tags = {
    Name        = "${var.project}-web-logs"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "cli" {
  name              = "/ecs/${var.project}-cli"
  retention_in_days = 7
  
  tags = {
    Name        = "${var.project}-cli-logs"
    Environment = var.environment
  }
}

# ECSタスク実行ロール
resource "aws_iam_role" "task_execution_role" {
  name = "${var.project}-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project}-task-execution-role"
    Environment = var.environment
  }
}

# ECSタスク実行ロールへのポリシーアタッチ
resource "aws_iam_role_policy_attachment" "task_execution_role_policy" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECSタスクロール
resource "aws_iam_role" "task_role" {
  name = "${var.project}-${var.environment}-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

# タスクロールに必要な権限を付与するポリシー
resource "aws_iam_policy" "task_role_cloudwatch" {
  name        = "${var.project}-${var.environment}-task-role-cloudwatch"
  description = "Allow ECS tasks to send logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

# タスクロールへのポリシーアタッチ
resource "aws_iam_role_policy_attachment" "task_role_cloudwatch" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.task_role_cloudwatch.arn
}

# ECSタスクロールにS3アクセス許可をアタッチ
resource "aws_iam_policy" "task_role_s3_access" {
  name        = "${var.project}-${var.environment}-task-role-s3-access"
  description = "Policy for ECS to access S3"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:s3:::${var.project}-*/*",
          "arn:aws:s3:::${var.project}-*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "task_role_s3_access" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.task_role_s3_access.arn
}

# ECSタスクロールにSSM Session Managerアクセス許可を追加
resource "aws_iam_policy" "task_role_ssm_access" {
  name        = "${var.project}-${var.environment}-task-role-ssm-access"
  description = "Policy for ECS to allow SSM Session Manager access"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
          "ssm:UpdateInstanceInformation"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "task_role_ssm_access" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.task_role_ssm_access.arn
}

# Webサービス用タスク定義
resource "aws_ecs_task_definition" "web" {
  family                   = "${var.project}-${var.environment}-web"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.task_execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn

  container_definitions = jsonencode([
    {
      name      = "${var.project}-${var.environment}-web"
      image     = var.web_image
      essential = true
      
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
      
      environment = concat([
        {
          name  = "APP_ENV"
          value = var.app_env
        },
        {
          name  = "DB_TYPE"
          value = var.db_type
        },
        {
          name  = "DB_HOST"
          value = var.db_host
        },
        {
          name  = "DB_NAME"
          value = var.db_name
        },
        {
          name  = "DB_USER"
          value = var.db_username
        },
        {
          name  = "DB_PASSWORD"
          value = var.db_password
        },
        {
          name  = "DB_PORT"
          value = tostring(var.db_port)
        },
        {
          name  = "DB_SSL_MODE"
          value = var.db_ssl_mode
        }
      ], var.additional_environment_variables)

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.web.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "web"
        }
      }
    }
  ])

  tags = {
    Name        = "${var.project}-web-task"
    Environment = var.environment
  }
}

# CLIサービス用タスク定義
resource "aws_ecs_task_definition" "cli" {
  family                   = "${var.project}-${var.environment}-cli"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.task_execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn

  container_definitions = jsonencode([
    {
      name      = "${var.project}-${var.environment}-cli"
      image     = var.cli_image
      essential = true
      
      environment = concat([
        {
          name  = "APP_ENV"
          value = var.app_env
        },
        {
          name  = "DB_TYPE"
          value = var.db_type
        },
        {
          name  = "DB_HOST"
          value = var.db_host
        },
        {
          name  = "DB_NAME"
          value = var.db_name
        },
        {
          name  = "DB_USER"
          value = var.db_username
        },
        {
          name  = "DB_PASSWORD"
          value = var.db_password
        },
        {
          name  = "DB_PORT"
          value = tostring(var.db_port)
        },
        {
          name  = "DB_SSL_MODE"
          value = var.db_ssl_mode
        }
      ], var.additional_environment_variables)

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.cli.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "cli"
        }
      }
    }
  ])

  tags = {
    Name        = "${var.project}-cli-task"
    Environment = var.environment
  }
}

# Webサービス
resource "aws_ecs_service" "web" {
  name            = "${var.project}-web-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.web.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  enable_execute_command = true

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.web_security_group_id]
    assign_public_ip = var.assign_public_ip
  }

  dynamic "load_balancer" {
    for_each = var.use_alb && var.target_group_arn != null ? [1] : []
    content {
      target_group_arn = var.target_group_arn
      container_name   = "${var.project}-${var.environment}-web"
      container_port   = var.container_port
    }
  }

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  health_check_grace_period_seconds  = var.use_alb ? 60 : 0

  tags = {
    Name        = "${var.project}-web-service"
    Environment = var.environment
  }
}

# Auto Scaling
resource "aws_appautoscaling_target" "web_service" {
  count              = var.enable_autoscaling ? 1 : 0
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.web.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.min_capacity
  max_capacity       = var.max_capacity
}

# CPU使用率に基づくスケーリングポリシー
resource "aws_appautoscaling_policy" "web_cpu" {
  count              = var.enable_autoscaling ? 1 : 0
  name               = "${var.project}-${var.environment}-web-cpu-scaling"
  service_namespace  = aws_appautoscaling_target.web_service[0].service_namespace
  resource_id        = aws_appautoscaling_target.web_service[0].resource_id
  scalable_dimension = aws_appautoscaling_target.web_service[0].scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 80 # スケールアウト条件: CPU使用率80%超過
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# メモリ使用率に基づくスケーリングポリシー
resource "aws_appautoscaling_policy" "web_memory" {
  count              = var.enable_autoscaling ? 1 : 0
  name               = "${var.project}-${var.environment}-web-memory-scaling"
  service_namespace  = aws_appautoscaling_target.web_service[0].service_namespace
  resource_id        = aws_appautoscaling_target.web_service[0].resource_id
  scalable_dimension = aws_appautoscaling_target.web_service[0].scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = 80 # スケールアウト条件: メモリ使用率80%超過
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# スケールイン用ステップスケーリングポリシー
resource "aws_appautoscaling_policy" "web_scale_in" {
  count              = var.enable_autoscaling ? 1 : 0
  name               = "${var.project}-${var.environment}-web-scale-in"
  service_namespace  = aws_appautoscaling_target.web_service[0].service_namespace
  resource_id        = aws_appautoscaling_target.web_service[0].resource_id
  scalable_dimension = aws_appautoscaling_target.web_service[0].scalable_dimension
  policy_type        = "StepScaling"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = "Average"
    
    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}

# スケールイン用アラーム（CPU使用率20%未満が5分間続いた場合）
resource "aws_cloudwatch_metric_alarm" "web_cpu_low" {
  count               = var.enable_autoscaling ? 1 : 0
  alarm_name          = "${var.project}-${var.environment}-web-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 20 # スケールイン条件: CPU使用率20%未満
  alarm_description   = "CPU使用率が20%を下回っている状態が5分間続いた場合にスケールイン"
  
  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.web.name
  }
  
  alarm_actions = [aws_appautoscaling_policy.web_scale_in[0].arn]
  
  tags = {
    Name        = "${var.project}-${var.environment}-web-cpu-low"
    Environment = var.environment
  }
}

# 現在のリージョンを取得
data "aws_region" "current" {}

# ALBなし構成でRoute53を自動更新するLambda関数（オプショナル）
# Lambda関数のコードを作成
resource "local_file" "lambda_code" {
  count   = var.assign_public_ip && !var.use_alb && var.route53_zone_id != null ? 1 : 0
  content = <<-EOT
// Lambda関数本体
const AWS = require('aws-sdk');
const ecs = new AWS.ECS();
const ec2 = new AWS.EC2();
const route53 = new AWS.Route53();

exports.handler = async (event) => {
  const { HOSTED_ZONE_ID, DOMAIN_NAME, CLUSTER_NAME, SERVICE_NAME } = process.env;
  
  console.log('Starting Route53 updater for ECS task');
  console.log('Environment:', { HOSTED_ZONE_ID, DOMAIN_NAME, CLUSTER_NAME, SERVICE_NAME });
  
  try {
    // タスクリストを取得
    console.log(`Getting tasks for service $${SERVICE_NAME} in cluster $${CLUSTER_NAME}`);
    const tasks = await ecs.listTasks({
      cluster: CLUSTER_NAME,
      serviceName: SERVICE_NAME,
      desiredStatus: 'RUNNING'
    }).promise();
    
    if (!tasks.taskArns || tasks.taskArns.length === 0) {
      console.log('No running tasks found');
      return { status: 'error', message: 'No running tasks found' };
    }
    
    console.log(`Found $${tasks.taskArns.length} running tasks`);
    
    // タスクの詳細を取得
    const taskDetails = await ecs.describeTasks({
      cluster: CLUSTER_NAME,
      tasks: [tasks.taskArns[0]]
    }).promise();
    
    const task = taskDetails.tasks[0];
    if (!task || !task.attachments || task.attachments.length === 0) {
      console.log('No network attachments found for task');
      return { status: 'error', message: 'No network attachments found' };
    }
    
    // ネットワークインターフェースIDを取得
    const eniDetails = task.attachments[0].details;
    const eniDetail = eniDetails.find(detail => detail.name === 'networkInterfaceId');
    
    if (!eniDetail) {
      console.log('Network interface ID not found');
      return { status: 'error', message: 'Network interface ID not found' };
    }
    
    const eniId = eniDetail.value;
    console.log(`Found ENI ID: $${eniId}`);
    
    // ネットワークインターフェースからパブリックIPを取得
    const eniResponse = await ec2.describeNetworkInterfaces({
      NetworkInterfaceIds: [eniId]
    }).promise();
    
    if (!eniResponse.NetworkInterfaces || !eniResponse.NetworkInterfaces[0].Association) {
      console.log('No public IP associated with ENI');
      return { status: 'error', message: 'No public IP found' };
    }
    
    const publicIp = eniResponse.NetworkInterfaces[0].Association.PublicIp;
    console.log(`Found public IP: $${publicIp}`);
    
    // Route53のレコードを更新 - レコード名はecs_directに統一
    console.log(`Updating Route53 record for $${DOMAIN_NAME} to $${publicIp}`);
    const result = await route53.changeResourceRecordSets({
      HostedZoneId: HOSTED_ZONE_ID,
      ChangeBatch: {
        Changes: [
          {
            Action: 'UPSERT',
            ResourceRecordSet: {
              Name: DOMAIN_NAME,
              Type: 'A',
              TTL: 60,
              ResourceRecords: [{ Value: publicIp }]
            }
          }
        ]
      }
    }).promise();
    
    console.log('Route53 record updated successfully');
    return { status: 'success', publicIp, recordUpdated: true };
  } catch (error) {
    console.error('Error:', error);
    return { status: 'error', message: error.message };
  }
};
  EOT
  filename = "${path.module}/lambda_functions/index.js"

  # ファイルが変更されたときに再作成が必要
  lifecycle {
    create_before_destroy = true
  }
}

# Lambda関数のパッケージ化（インラインでZIP作成）
data "archive_file" "lambda_package" {
  count       = var.assign_public_ip && !var.use_alb && var.route53_zone_id != null ? 1 : 0
  type        = "zip"
  output_path = "${path.module}/lambda_functions/lambda_function.zip"
  
  source {
    content  = local_file.lambda_code[0].content
    filename = "index.js"
  }

  depends_on = [local_file.lambda_code]
}

# Lambda実行用のIAMロール
resource "aws_iam_role" "lambda_role" {
  count = var.assign_public_ip && !var.use_alb && var.route53_zone_id != null ? 1 : 0
  name  = "${var.project}-${var.environment}-lambda-route53-updater-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project}-${var.environment}-lambda-route53-updater-role"
    Environment = var.environment
  }
}

# Lambda実行に必要な権限ポリシー
resource "aws_iam_policy" "lambda_policy" {
  count       = var.assign_public_ip && !var.use_alb && var.route53_zone_id != null ? 1 : 0
  name        = "${var.project}-${var.environment}-lambda-route53-updater-policy"
  description = "Policy for Lambda to update Route53 records for ECS tasks"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:ListTasks",
          "ecs:DescribeTasks"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeNetworkInterfaces"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets"
        ]
        Resource = "arn:aws:route53:::hostedzone/*"
      }
    ]
  })

  tags = {
    Name        = "${var.project}-${var.environment}-lambda-route53-updater-policy"
    Environment = var.environment
  }
}

# IAMポリシーをロールにアタッチ
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  count      = var.assign_public_ip && !var.use_alb && var.route53_zone_id != null ? 1 : 0
  role       = aws_iam_role.lambda_role[0].name
  policy_arn = aws_iam_policy.lambda_policy[0].arn
}

# Lambda関数リソース
resource "aws_lambda_function" "update_route53" {
  count         = var.assign_public_ip && !var.use_alb && var.route53_zone_id != null ? 1 : 0
  function_name = "${var.project}-${var.environment}-update-route53"
  role          = aws_iam_role.lambda_role[0].arn
  handler       = "index.handler"
  runtime       = "nodejs16.x"
  timeout       = 30
  memory_size   = 128

  environment {
    variables = {
      HOSTED_ZONE_ID = var.route53_zone_id
      DOMAIN_NAME    = var.domain_name
      CLUSTER_NAME   = aws_ecs_cluster.main.name
      SERVICE_NAME   = aws_ecs_service.web.name
    }
  }

  filename         = data.archive_file.lambda_package[0].output_path
  source_code_hash = data.archive_file.lambda_package[0].output_base64sha256

  tags = {
    Name        = "${var.project}-${var.environment}-update-route53"
    Environment = var.environment
  }
}

# AWS CLIが不要な方法で初期実行を設定
# null_resourceを削除し、CloudWatchイベントルールにdelay_event_patternを追加
resource "aws_cloudwatch_event_rule" "ecs_task_state_change" {
  count       = var.assign_public_ip && !var.use_alb && var.route53_zone_id != null ? 1 : 0
  name        = "${var.project}-${var.environment}-ecs-task-state-change"
  description = "Capture ECS task state changes"

  event_pattern = jsonencode({
    source      = ["aws.ecs"]
    detail-type = ["ECS Task State Change"]
    detail = {
      clusterArn = [aws_ecs_cluster.main.arn]
      lastStatus = ["RUNNING"]
      group      = ["service:${aws_ecs_service.web.name}"]
    }
  })

  tags = {
    Name        = "${var.project}-${var.environment}-ecs-task-state-change"
    Environment = var.environment
  }
}

# CloudWatch Event Target - Lambda関数をターゲットに設定
resource "aws_cloudwatch_event_target" "lambda" {
  count     = var.assign_public_ip && !var.use_alb && var.route53_zone_id != null ? 1 : 0
  rule      = aws_cloudwatch_event_rule.ecs_task_state_change[0].name
  target_id = "InvokeLambda"
  arn       = aws_lambda_function.update_route53[0].arn
}

# Lambda関数のCloudWatchイベントからの呼び出し許可
resource "aws_lambda_permission" "allow_cloudwatch" {
  count         = var.assign_public_ip && !var.use_alb && var.route53_zone_id != null ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_route53[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ecs_task_state_change[0].arn
} 
