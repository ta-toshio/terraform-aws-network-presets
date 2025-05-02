# myproject インフラストラクチャセットアップ

このディレクトリには、myprojectサービスのインフラストラクチャ初期セットアップ用のTerraformコードが含まれています。

## 目的

このセットアップコードは以下のリソースを作成します：

1. デプロイ用IAMユーザーとアクセス権限
2. 環境ごとのECRリポジトリ（開発/ステージング/本番）
3. Terraform状態管理用のS3バケットとDynamoDBテーブル

## 使用方法

### 前提条件

- AWS CLIがインストールされていること
- AWS管理者権限を持つアカウントの認証情報が設定されていること
- Terraformがインストールされていること

### 手動実行

```bash
# 初期化
cd terraform/aws/setup
terraform init

# 計画の確認
terraform plan

# 適用
terraform apply
```

### GitHub Actionsでの実行

リポジトリの「Actions」タブから「Initial Infrastructure Setup」ワークフローを実行します。

必要なシークレット：
- `ADMIN_AWS_ACCESS_KEY_ID`: AWS管理者アカウントのアクセスキーID
- `ADMIN_AWS_SECRET_ACCESS_KEY`: AWS管理者アカウントのシークレットアクセスキー

### 出力値の利用

セットアップ実行後、以下の出力値が得られます：

- `deploy_user_access_key`: デプロイ用IAMユーザーのアクセスキーID
- `deploy_user_secret_key`: デプロイ用IAMユーザーのシークレットアクセスキー
- `ecr_repositories`: 作成されたECRリポジトリのリスト

これらの値を使用して、GitHub Actionsのシークレットとして以下を設定します：

- `AWS_ACCESS_KEY_ID`: デプロイ用IAMユーザーのアクセスキーID
- `AWS_SECRET_ACCESS_KEY`: デプロイ用IAMユーザーのシークレットアクセスキー

## 注意事項

- このセットアップは通常、プロジェクト開始時に**一度だけ**実行します
- セットアップで作成されるリソースは、以降のすべてのデプロイで使用されます
- セキュリティ上、出力されるIAMユーザーの認証情報は安全に管理してください
- 定期的なキーローテーションを推奨します 
