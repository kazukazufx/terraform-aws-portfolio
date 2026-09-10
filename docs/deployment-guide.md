# 構築・更新・削除手順

## 前提ツール

- AWSアカウント
- AWS CLI v2.32.0以上
- Terraform 1.10以上
- Docker
- GitHubアカウント
- 外部レジストラで取得済みの`aws-demo.blog`

ドメイン登録はTerraformの管理対象に含めない。Route 53 Public Hosted ZoneとDNS RecordをTerraformで管理し、外部レジストラにはRoute 53が発行するネームサーバーを設定する。

## AWS CLIの一時認証

```bash
aws login --profile portfolio-admin --region ap-northeast-1
aws sts get-caller-identity --profile portfolio-admin
```

初回構築には各サービスとIAMを作成できる権限が必要となる。構築後のGitHub ActionsはTerraformが作成する専用OIDC Roleを使用する。

## Terraform State用S3バケットの作成

バケット名は世界で一意にする。

```bash
cp bootstrap/terraform.tfvars.example bootstrap/terraform.tfvars
# state_bucket_nameを一意な名前へ編集

terraform -chdir=bootstrap init
terraform -chdir=bootstrap plan -out=bootstrap.tfplan -var-file=terraform.tfvars
terraform -chdir=bootstrap apply bootstrap.tfplan
```

`bootstrap/terraform.tfstate`はGitの管理対象外とする。State用S3バケットには誤削除を防ぐLifecycle設定を適用している。

## AWS基盤の作成

```bash
cp infra/backend.hcl.example infra/backend.hcl
cp infra/terraform.tfvars.example infra/terraform.tfvars
```

次の値を環境に合わせて変更する。

- `infra/backend.hcl`の`bucket`
- `infra/terraform.tfvars`の`state_bucket_name`
- `infra/terraform.tfvars`の`alert_email`
- GitHub Owner IDとRepository ID
- `monthly_budget_amount`

`backend.hcl`と`terraform.tfvars`はGitの管理対象外とする。

初回だけRoute 53 Public Hosted Zoneを先に作成する。

```bash
export AWS_PROFILE=portfolio-admin
terraform -chdir=infra init -backend-config=backend.hcl
terraform -chdir=infra plan -target=aws_route53_zone.portfolio -out=dns.tfplan -var-file=terraform.tfvars
terraform -chdir=infra apply dns.tfplan
terraform -chdir=infra output route53_name_servers
```

出力された4つのネームサーバーを外部レジストラへ設定し、DNSへの反映を確認する。

```bash
dig NS aws-demo.blog +short
```

残りのAWS基盤を作成する。

```bash
export AWS_PROFILE=portfolio-admin
terraform -chdir=infra fmt -check
terraform -chdir=infra validate
terraform -chdir=infra plan -out=tfplan -var-file=terraform.tfvars
terraform -chdir=infra apply tfplan
```

初回のECS Serviceリソースは、存在しないイメージの起動待ちでTerraform Applyが停止しないようDesired Count 0で作成される。Auto Scaling Targetの登録後は最小2タスクが適用されるため、続けてアプリWorkflowを実行し、正常なイメージで2タスクを起動する。

AWS BudgetsとSNSから届く確認メールを承認する。SNSの購読を承認するまでCloudWatch Alarmのメールは配信されない。

## ローカル実行

```bash
docker compose up --build
```

- Web画面: http://localhost:8000
- API仕様: http://localhost:8000/docs
- ヘルスチェック: http://localhost:8000/health
- 制作物API: http://localhost:8000/api/projects

```bash
docker compose down
# DBデータも削除する場合
docker compose down --volumes
```

## GitHub Actionsの設定

GitHub Environment `dev`へ次の値を登録する。

| 種類 | 名前 | 値 |
|---|---|---|
| Environment variable | `AWS_ACCOUNT_ID` | AWSアカウントID |
| Environment variable | `AWS_APP_ROLE_ARN` | `github_app_role_arn` Output |
| Environment variable | `AWS_TERRAFORM_ROLE_ARN` | `github_terraform_role_arn` Output |
| Environment variable | `TF_STATE_BUCKET` | State用S3バケット名 |
| Environment secret | `ALERT_EMAIL` | 通知先メールアドレス |

Terraform ApplyはGitHub Actionsの`Terraform plan and apply`を手動実行し、`apply`を有効にした場合だけ反映される。

アプリケーションの変更が`main`へ反映されると、Docker Build、ECR Push、DB Migration、Task Definition登録、ECS Service更新が順番に実行される。

## プロフィール情報の更新

表示内容は`app/content.py`で管理する。DBの初期データは`app/migrations/versions/20260903_01_create_projects.py`に定義されている。

適用済みのMigrationは直接書き換えず、新しいMigrationを追加する。

```bash
alembic -c app/alembic.ini revision -m "describe change"
```

## 検証

```bash
python -m pip install -r app/requirements-dev.txt
ruff check app tests
python -m pytest
terraform fmt -check -recursive
terraform -chdir=bootstrap init -backend=false
terraform -chdir=bootstrap validate
terraform -chdir=infra init -backend=false
terraform -chdir=infra validate
terraform -chdir=infra test
docker build -t portfolio:test .
```

CheckovはCIで検出結果を可視化する。必須の設計ポリシーは`terraform test`で検証する。

## AWS基盤の削除

削除対象をPlanで確認してから適用する。Auroraのデータは初期Migrationから再作成できる前提のため、最終Snapshotは保存しない。

```bash
export AWS_PROFILE=portfolio-admin
terraform -chdir=infra plan -destroy -out=destroy.tfplan -var-file=terraform.tfvars
terraform -chdir=infra apply destroy.tfplan
```

ALB、WAF、ECS、ECR内のイメージ、Aurora、Secrets ManagerのSecretなどが削除される。Auroraのデータは復元できない。

次のリソースは`infra`の削除対象外となる。

- 外部レジストラで登録したドメイン
- `bootstrap`で管理するState用S3バケット

削除後はBillingとCost Explorerを確認し、意図しない有料リソースが残っていないことを確認する。
