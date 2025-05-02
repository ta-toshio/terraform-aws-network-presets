# myproject インフラストラクチャ デプロイ手順

このガイドでは、Terraformを使用してmyprojectサービスのインフラストラクチャをセットアップし、さまざまな環境（開発、ステージング、本番）にデプロイする方法について説明します。

## 前提条件

- AWS CLIがインストール済みで、適切な権限を持つプロファイルが設定されていること
- Terraform v1.0.0以上がインストールされていること
- 必要なドメイン名がRoute53に登録されていること

## 1. リポジトリのクローン

```bash
git clone https://github.com/your-organization/myproject_service.git
cd myproject_service
```

## 2. インフラストラクチャの初期セットアップ

myprojectサービスをデプロイする前に、初期セットアップを行う必要があります。このプロセスは通常、プロジェクト開始時に一度だけ実行します。

### 手動セットアップ

```bash
cd terraform/aws/setup

# 初期化
terraform init

# 計画の確認
terraform plan

# セットアップの実行
terraform apply
```

### GitHub Actionsでのセットアップ

リポジトリの「Actions」タブから「Initial Infrastructure Setup」ワークフローを実行します。必要なシークレット：

- `ADMIN_AWS_ACCESS_KEY_ID`: AWS管理者アカウントのアクセスキーID
- `ADMIN_AWS_SECRET_ACCESS_KEY`: AWS管理者アカウントのシークレットアクセスキー

### セットアップ後の作業

セットアップ完了後、以下の出力値が表示されます：

- デプロイ用IAMユーザーのアクセスキーID
- デプロイ用IAMユーザーのシークレットアクセスキー
- 作成されたECRリポジトリの一覧

これらの値をGitHubシークレットとして設定します：
- `AWS_ACCESS_KEY_ID`: デプロイ用IAMユーザーのアクセスキーID
- `AWS_SECRET_ACCESS_KEY`: デプロイ用IAMユーザーのシークレットアクセスキー

## 3. 環境ごとの設定ファイルの準備

各環境（dev、staging、production）のディレクトリに移動し、`terraform.tfvars`ファイルを作成します。

```bash
# 開発環境の場合
cd terraform/aws/dev
cp terraform.tfvars.example terraform.tfvars
# エディタで開いて必要な値を設定
```

同様に、`staging`と`production`環境についても設定ファイルを準備します。

## 4. 環境別のインフラストラクチャデプロイ

### 開発環境のデプロイ

開発環境は最小構成で、ALBなしの設定をデフォルトとしています。

```bash
cd terraform/aws/deploy/dev

# 初期化
terraform init

# 計画の確認
terraform plan

# デプロイ
terraform apply
```

特定の構成を選択する場合は、Terraformワークスペースを使用します：

```bash
# ALBありの構成に切り替える場合
terraform workspace new public-with-alb
terraform plan
terraform apply
```

### ステージング環境のデプロイ

ステージング環境は本番に近い構成を持ちますが、リソースサイズは若干小さめに設定されています。

```bash
cd terraform/aws/staging

# 初期化
terraform init

# デフォルト構成（ALBあり）での計画確認
terraform plan

# デプロイ
terraform apply
```

ワークスペースを変更する場合：

```bash
# コスト削減構成（ALBなし）に切り替える場合
terraform workspace new public-no-alb
terraform plan
terraform apply
```

### 本番環境のデプロイ

本番環境はセキュリティを重視した構成がデフォルトとなっています。

```bash
cd terraform/aws/production

# 初期化
terraform init

# デフォルト構成（プライベートサブネット+ALB）での計画確認
terraform plan

# デプロイ
terraform apply
```

ワークスペースを変更する場合：

```bash
# 別の構成に切り替える場合
terraform workspace new private-no-alb
terraform plan
terraform apply
```

## 5. GitHub Actionsを使ったCI/CDデプロイ

リポジトリにはデプロイ用のGitHub Actionsワークフローが含まれています：

- **開発環境**: `Dev Environment Deploy` ワークフロー
- **ステージング/本番環境**: `Main Deployment Flow` ワークフロー

これらのワークフローは、GitHubのActionsタブから手動で実行するか、mainやproductionブランチへのプッシュによって自動的にトリガーされます。

## 6. 環境間の切り替え

既存の環境を切り替える場合は、ワークスペースを選択します：

```bash
# 既存のワークスペース一覧の確認
terraform workspace list

# ワークスペースの選択
terraform workspace select <ワークスペース名>

# 変更の適用
terraform plan
terraform apply
```

## 7. リソースの更新と設定変更

設定を変更する場合は、対応する環境の変数ファイルを編集し、変更を適用します：

```bash
# 変数ファイルを編集
vi terraform.tfvars

# 変更の適用
terraform plan
terraform apply
```

## 8. 環境の削除

不要になった環境を削除する場合：

```bash
# 削除前に計画を確認
terraform plan -destroy

# 削除の実行
terraform destroy
```

## トラブルシューティング

### 状態ファイルの問題

S3バケットに保存されている状態ファイルに問題がある場合：

```bash
# 状態ファイルのリスト表示
aws s3 ls s3://myproject-terraform-state/

# 手動でのバックアップ作成
aws s3 cp s3://myproject-terraform-state/deploy/dev/terraform.tfstate s3://myproject-terraform-state/deploy/dev/terraform.tfstate.backup.$(date +%Y%m%d)
```

### デプロイ失敗時の対応

リソースの作成に失敗した場合、以下の順序で対応します：

1. エラーメッセージを確認
2. 問題のあるリソースのみを削除してから再適用：
   ```bash
   terraform destroy -target=module.problematic_module
   terraform apply
   ```

### IPアドレス変更時のDNS更新

ALBなし構成でECSタスクのIPアドレスが変更された場合、DNSの更新が必要です：

```bash
# 現在のIPアドレスを確認
aws ecs describe-tasks --cluster myproject-dev-cluster --tasks $(aws ecs list-tasks --cluster myproject-dev-cluster --query 'taskArns[0]' --output text) --query 'tasks[0].attachments[0].details[?name==`privateIPv4Address`].value' --output text

# Route53レコードを更新
terraform apply
``` 
