# terraform-aws-network-presets

AWS 上でサービスを動かすための仮想ネットワーク（VPC、サブネット、ルートテーブル、NAT ゲートウェイなど）を Terraform を用いて構築・管理するための再利用可能な構成単位（モジュール）です

## 前提条件

- AWS CLIがインストール済みで、適切な権限を持つプロファイルが設定されていること
- Terraform v1.0.0以上がインストールされていること
- 必要なドメイン名がRoute53に登録されていること


## 1. 初期セットアップ

myprojectサービスをデプロイする前に、初期セットアップを行う必要があります。このプロセスは通常、プロジェクト開始時に一度だけ実行します。

### 手動セットアップ

```bash
# 初期化
docker compose run --rm terraform -chdir=setup init

# 計画の確認
docker compose run --rm terraform -chdir=setup plan

# セットアップの実行
docker compose run --rm terraform -chdir=setup apply
```

### セットアップ後の作業

セットアップ完了後、以下の出力値が表示されます：

- デプロイ用IAMユーザーのアクセスキーID
- デプロイ用IAMユーザーのシークレットアクセスキー
- 作成されたECRリポジトリの一覧

Github ActoinsでCI/CDをする場合、これらの値をGitHubシークレットとして設定します：
- `AWS_ACCESS_KEY_ID`: デプロイ用IAMユーザーのアクセスキーID
- `AWS_SECRET_ACCESS_KEY`: デプロイ用IAMユーザーのシークレットアクセスキー

## 2. 環境ごとの設定ファイルの準備

各環境（dev、staging、production）のディレクトリに移動し、`terraform.tfvars`ファイルを作成します。

```bash
# 開発環境の場合
# エディタで開いて必要な値を設定
cp terraform.tfvars.sample deply/dev/terraform.tfvars
```

同様に、`staging`と`production`環境についても設定ファイルを準備します。

## 3. 環境別のインフラストラクチャデプロイ

### 開発環境のデプロイ


```bash
# 初期化
docker compose --env-file .env.dev run --rm --entrypoint sh terraform -c "\
  terraform -chdir=/tf/deploy/dev workspace select -or-create public-with-alb && \
  terraform -chdir=/tf/deploy/dev init"

# 計画の確認
docker compose --env-file .env.dev run --rm --entrypoint sh terraform -c "\
  terraform -chdir=/tf/deploy/dev workspace select -or-create public-with-alb && \
  terraform -chdir=/tf/deploy/dev plan"

# デプロイ
docker compose --env-file .env.dev run --rm --entrypoint sh terraform -c "\
  terraform -chdir=/tf/deploy/dev workspace select -or-create public-with-alb && \
  terraform -chdir=/tf/deploy/dev apply"
```

### ステージング環境のデプロイ

ステージング環境は本番に近い構成を持ちますが、リソースサイズは若干小さめに設定されています。

```bash
docker compose --env-file .env.staging run --rm --entrypoint sh terraform -c "\
  terraform -chdir=/tf/deploy/staging workspace select -or-create public-with-alb && \
  terraform -chdir=/tf/deploy/staging [init|plan|apply|output]"
```

### 本番環境のデプロイ

本番環境はセキュリティを重視した構成がデフォルトとなっています。

```bash
docker compose --env-file .env.production run --rm --entrypoint sh terraform -c "\
  terraform -chdir=/tf/deploy/production workspace select -or-create public-with-alb && \
  terraform -chdir=/tf/deploy/production [init|plan|apply|output]"
```

## 4. 環境の削除

不要になった環境を削除する場合：

```bash
# 削除前に計画を確認
docker compose .. terraform .. plan -destroy

# 削除の実行
docker compose .. terraform .. destroy
```
