# myproject サービス AWS アーキテクチャ設計書

## 1. 全体構成図

```
                +----------------+
                |   Route53      |
                | (myproject.dev)   |
                +--------+-------+
                         |
                         v
+----------------+    +--+-------------+    +----------------+
|   Amplify      +--->+  ALB          +<---+  ACM           |
| (Next.js Web)  |    | (HTTPSエンドポイント)|  (SSL証明書)    |
+----------------+    +--+-------------+    +----------------+
                         |
                         v
                  +------+--------+
                  |  ECS Fargate  |
                  | (Webサーバー)  |
                  +------+--------+
                         |
         +---------------+---------------+
         |                               |
         v                               v
+--------+---------+            +--------+---------+
| ECS Fargate Task |            |  RDS PostgreSQL  |
| (CLIコマンド実行) |            |    (17.4)        |
+--------+---------+            +------------------+
```

**代替アーキテクチャ（ALBなし構成）:**

```
                +----------------+
                |   Route53      |
                | (myproject.dev)   |
                +--------+-------+
                         |
                         v
+----------------+    +--+-------------+    
|   Amplify      |    |  ECS Fargate  |    
| (Next.js Web)  |    | (Webサーバー)  |    
+----------------+    +--+-------------+    
                         |
         +---------------+---------------+
         |                               |
         v                               v
+--------+---------+            +--------+---------+
| ECS Fargate Task |            |  RDS PostgreSQL  |
| (CLIコマンド実行) |            |    (17.4)        |
+--------+---------+            +------------------+
```

## 2. インフラストラクチャ設計

### ネットワーク構成 (コスト最適化版)

- **VPC**: 10.0.0.0/16
  - **パブリックサブネット**:
    - ap-northeast-1a: 10.0.1.0/24
    - ap-northeast-1c: 10.0.2.0/24
  - **プライベートサブネット** (データ層のみ):
    - ap-northeast-1a: 10.0.5.0/24
    - ap-northeast-1c: 10.0.6.0/24

- **ゲートウェイ**:
  - Internet Gateway: パブリックサブネット用

- **エンドポイント**:
  - S3 Gateway Endpoint: S3アクセス用 (無料)

### コンピューティングリソース

- **ECS Fargate** (パブリックサブネットに配置):
  - Webサーバークラスター: 
    - CPU: 0.25 vCPU
    - メモリ: 0.5 GB
    - 常時1インスタンス実行
    - パブリックサブネットに配置 (NAT Gateway不要)
  - CLIタスク: 
    - CPU: 0.25 vCPU
    - メモリ: 0.5 GB
    - オンデマンド実行
    - パブリックサブネットに配置 (NAT Gateway不要)

- **AWS Amplify**:
  - Next.jsフロントエンド
  - GitHub連携でCICD
  - カスタムドメイン: myproject.dev

### データストア

- **RDS PostgreSQL**:
  - バージョン: 17.4
  - インスタンスタイプ: db.t3.micro (無料枠)
  - ストレージ: 20GB
  - マルチAZ: 無効（コスト削減）
  - バックアップ: 3日間保持
  - **プライベートサブネットに配置** (セキュリティ確保)

### ネットワークアクセス管理

- **ALB** (オプション):
  - HTTPをHTTPSにリダイレクト
  - WebサーバーのFargateタスクにトラフィックを分散
  - ヘルスチェック: `/health` または `/ping` エンドポイント
  - パブリックサブネットに配置

- **セキュリティグループ**:
  - ALB使用時: ALBは80/443ポートを外部公開、Webサーバーは**ALBからの8080ポートのみ許可**
  - ALB未使用時: Webサーバーは**80/443ポートを直接公開**、8080ポートを内部でリダイレクト
  - CLI: **必要最小限の外部接続のみ許可**
  - RDS: Webサーバーと CLIタスクからの5432ポートのみ許可

## 3. スケーリング戦略

- **Auto Scaling**:
  - 最小容量: 1
  - 最大容量: 2
  - スケールアウト条件: CPU使用率80%超過
  - スケールイン条件: CPU使用率20%未満

## 4. モニタリングとアラート

- **CloudWatch**:
  - ECS CPU使用率アラーム（85%超過）
  - RDS CPU使用率アラーム（85%超過）
  - RDS空き容量アラーム（10%未満）
  - アプリケーションログのモニタリング
  - **セキュリティグループ関連のメトリクス監視** (パブリック配置の補完策)

## 5. セキュリティ設計

- **暗号化**:
  - RDSストレージ暗号化
  - HTTPS通信のみ許可
  - ALBからECSへの通信の制限

- **ネットワークセキュリティ強化**:
  - ALB使用時: Webサーバーは ALBからの接続のみを許可
  - ALB未使用時: Webサーバーは直接インターネットからのアクセスを受け付けるが、セキュリティグループで制限
  - CLIタスク: 必要な外部APIのみへのアクセス許可
  - RDSをプライベートサブネットに隔離し、ECSからの接続のみ許可

- **認証**:
  - Clerk認証サービス利用
  - セキュリティグループによるネットワークレベルの制限

## 6. コスト最適化

- **費用削減施策**:
  - **NAT Gateway不要** (月額約$35の削減)
  - **ALBを選択的に使用** (未使用時は月額約$25の削減)
  - Fargate最小スペック利用
  - RDS無料枠インスタンス利用
  - Auto Scalingによる需要に応じたキャパシティ調整
  - S3 Gateway Endpointによるデータ転送コスト削減

- **見積もり月額コスト**:
  - ALB: $25/月 (使用時) または $0 (未使用時)
  - ~~NAT Gateway: $35/月（データ転送料金別）~~ → $0 (削減)
  - ECS Fargate: 最小構成で約$15/月
  - RDS: 無料枠または$15/月
  - Route53: $0.50/月
  - Amplify: ビルド分単位の料金+ホスティング
  - 合計: 
    - ALB使用時: 約$55-65/月
    - ALB未使用時: 約$30-40/月 (ALB削除により約45%削減)

## 7. バックアップと災害対策

- **バックアップ戦略**:
  - RDS自動バックアップ: 3日間
  - データベース手動スナップショット: 重要な変更前
  - ソースコード: GitHub
  - コンテナイメージ: ECR

## 8. CI/CD パイプライン

- **フロントエンド (Amplify)**:
  - GitHub連携による自動デプロイ
  - mainブランチへのプッシュで自動ビルド・デプロイ

- **バックエンド (ECS)**:
  - GitHub Actionsを利用した自動ビルド
  - ECRへのイメージプッシュ
  - ECSサービスの更新

## 9. 運用管理

- **タスク実行方法**:
  - WebサーバーはECSサービスとして常時稼働
  - CLIコマンドはAWS CLIを使用して実行:
    ```
    aws ecs run-task --cluster myproject-cluster \
      --task-definition myproject-cli \
      --launch-type FARGATE \
      --network-configuration "awsvpcConfiguration={...}" \
      --overrides '{"containerOverrides": [{"name": "cli", "command": ["database", "migrate"]}]}'
    ```

## 10. 構成切り替えと移行計画

### 10.1 Terraformワークスペースによる環境切り替え

- **拡張ワークスペース構成**:
  - `public-with-alb`: パブリックサブネット + ALB使用（標準構成）
  - `public-no-alb`: パブリックサブネット + ALB未使用（最小コスト構成）
  - `private-with-alb`: プライベートサブネット + ALB使用（標準セキュリティ構成）
  - `private-no-alb`: プライベートサブネット + ALB未使用（特殊構成）

- **構成切り替えコマンド**:
  ```bash
  # 初期化
  $ cd terraform/aws
  $ terraform init

  # 各構成に切り替え
  $ terraform workspace select public-with-alb  # 標準構成
  $ terraform workspace select public-no-alb    # 最小コスト構成
  $ terraform workspace select private-with-alb # セキュリティ強化構成
  $ terraform apply
  ```

### 10.2 ALBなし構成のRoute53設定

#### Lambdaを使用した自動DNS更新（推奨アプローチ）

ALBなし構成でECSタスクのパブリックIPをDNSに自動的に登録するため、Lambda関数を使用しています：

```hcl
# ECSモジュール内でLambda関数を定義
resource "aws_lambda_function" "update_route53" {
  function_name = "${var.project}-${var.environment}-update-route53"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs16.x"
  
  environment {
    variables = {
      HOSTED_ZONE_ID = var.route53_zone_id
      DOMAIN_NAME    = var.domain_name
      CLUSTER_NAME   = aws_ecs_cluster.main.name
      SERVICE_NAME   = aws_ecs_service.web.name
    }
  }
  
  # Lambda関数のコードはTerraform内で生成
  filename         = data.archive_file.lambda_package.output_path
  source_code_hash = data.archive_file.lambda_package.output_base64sha256
}

# CloudWatchイベントでECSタスク状態変更を検知
resource "aws_cloudwatch_event_rule" "ecs_task_state_change" {
  event_pattern = jsonencode({
    source      = ["aws.ecs"]
    detail-type = ["ECS Task State Change"]
    detail = {
      clusterArn = [aws_ecs_cluster.main.arn]
      lastStatus = ["RUNNING"]
      group      = ["service:${aws_ecs_service.web.name}"]
    }
  })
}

# Route53レコード（初期ダミーレコード、Lambda関数により更新される）
resource "aws_route53_record" "ecs_direct" {
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"
  
  # 初期値は127.0.0.1（Lambda関数が実行されると上書きされる）
  records = ["127.0.0.1"]
  ttl     = 60
  
  # Lambda関数による更新を許可するため、変更を無視
  lifecycle {
    ignore_changes = [records]
  }
}
```

#### Lambda関数の動作フロー

1. **ECSタスク起動**: FargateタスクがRUNNING状態になると、CloudWatchイベントがトリガー
2. **Lambda実行**: Lambda関数が起動し、以下の処理を実行
   - ECSタスクのENI (Elastic Network Interface) を特定
   - ENIに割り当てられたパブリックIPアドレスを取得
   - Route53のAレコードを新しいIPアドレスで更新
3. **自動更新**: タスクが再起動や再デプロイされても自動的にDNSが更新

#### この実装の利点

- **完全自動化**: 手動介入が不要
- **信頼性**: タスク再起動時も自動的に新IPアドレスで更新
- **Terraformで完結**: 外部スクリプトやツールが不要
- **耐障害性**: エラーハンドリングとログ記録による監視容易性


## 11. セキュリティ注意事項

- パブリックサブネットにECSタスクを配置することによる潜在的なリスク
- ALBなし構成の場合、WebサーバーコンテナへのHTTPS対応が必要
- セキュリティグループの定期的な監査
- AWS Config/GuardDutyなどによる継続的なセキュリティモニタリング
- セキュリティスキャンの定期実施 

## 12. 環境分離戦略

### 12.1 環境分離の目的

- **開発環境（dev）**: 開発者向けの環境で、頻繁な変更と実験が可能
- **ステージング環境（staging）**: 本番環境に近い構成で、リリース前のテストとQAを実施
- **本番環境（production）**: エンドユーザー向けの安定した環境

### 12.2 Terraformでの環境分離実装方法

#### 環境ごとのディレクトリ構造

```
terraform/
├── setup/           # インフラ初期セットアップ用コード
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── modules/
│       ├── iam/     # デプロイ用IAMユーザーとポリシー
│       └── ecr/     # 初期ECRリポジトリ
├── deploy/          # 環境ごとのデプロイコード
│   ├── modules/     # 共通モジュール
│   ├── dev/         # 開発環境
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   ├── staging/     # ステージング環境
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   └── production/  # 本番環境
│       ├── main.tf
│       ├── variables.tf
│       └── terraform.tfvars
```

### 12.3 セットアップとデプロイの分離

セットアップとデプロイを明確に分離することで、以下のメリットがあります：

#### セットアップ (`terraform/aws/setup`)

- **目的**: インフラストラクチャの初期設定および共通リソースのプロビジョニング
- **実行タイミング**: プロジェクト初期または新環境追加時に一度だけ実行
- **管理するリソース**:
  - デプロイ用IAMユーザーとアクセス権限
  - ECRリポジトリ（環境ごと）
  - Terraform状態管理用のS3バケットとDynamoDBテーブル
  - 環境間で共有するその他のリソース

#### デプロイ (`terraform/aws/deploy`)

- **目的**: 各環境固有のリソースのプロビジョニングと継続的なデプロイ
- **実行タイミング**: CI/CDパイプラインや定期的なデプロイで実行
- **管理するリソース**:
  - ECSクラスターとサービス
  - RDSインスタンス
  - VPCとネットワーク設定
  - セキュリティグループ
  - ALB (必要な場合)
  - 環境固有のその他のリソース

### 12.4 セットアップフローとデプロイフローの分離

#### セットアップフロー

1. 管理者権限を持つAWSアカウントで一度だけ実行
2. デプロイ用のIAMユーザーとアクセスキーを生成
3. ECRリポジトリを環境ごとに作成
4. 生成されたアクセスキーとシークレットキーをGitHubシークレットに設定

```bash
# セットアップの実行例
cd terraform/aws/setup
terraform init
terraform apply
```

#### デプロイフロー

1. セットアップで作成したIAMユーザーの権限で実行
2. CI/CDパイプラインを通じて自動実行
3. 環境固有のリソースをプロビジョニング

```bash
# デプロイの実行例
cd terraform/aws/deploy/dev
terraform init
terraform workspace select public-no-alb
terraform apply
```

各環境のデプロイは引き続きTerraformワークスペースを使用して構成バリエーションを管理します。 
