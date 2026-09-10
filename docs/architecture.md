# アーキテクチャ設計

## 通信経路

```text
Internet
  │ HTTPS :443
  ▼
Route 53 ─ ACM Certificate
  │
  ▼
AWS WAF
  ├─ AWS Managed Core Rule Set
  ├─ Amazon IP Reputation List
  └─ IP別レート制限
  │
  ▼
Public ALB（2 AZ）
  │ HTTP :8000 / Security Group参照
  ▼
ECS/Fargate（Private App Subnet、Public IPなし、2 AZ）
  │ PostgreSQL :5432 / Security Group参照
  ▼
Aurora PostgreSQL Serverless v2（Private DB Subnet、2 AZ）

ECS/Fargate
  │ 外向き通信
  ▼
AZごとのNAT Gateway（Public Subnet、Elastic IP）
  │
  ▼
Internet Gateway ─ ECR / CloudWatch Logs / Secrets Manager / 外部API
```

## ECSをPrivate Subnetへ置く理由

Fargate TaskはPrivate App Subnetへ配置し、Public IPを割り当てません。Security GroupのInboundもALBのSecurity GroupからのPort 8000だけに限定し、ネットワーク経路とファイアウォールの両方でインターネットからTaskへの直接接続を防ぎます。

Private App SubnetはAZごとにRoute Tableを持ち、同じAZのNAT Gatewayへデフォルトルートを向けます。これにより、ECR、CloudWatch Logs、Secrets Manager、外部APIへの外向き通信を確保しながら、インターネット側から接続を開始することはできません。NAT Gatewayは2台分の固定費がかかるため、デモ公開期間だけ構築し、終了後はTerraformで削除します。

## Auroraの自動停止

- Aurora PostgreSQL Serverless v2を1 Writerで使用
- 最小0 ACU、最大1 ACU
- 10分間アイドルで自動停止
- `/health` はDBへ接続しないため、ALBの確認でAuroraを起こさない
- APIは接続失敗時に再試行する
- SQLAlchemyはConnection Poolを保持しないため、不要な接続が自動停止を妨げない

自動停止後の最初のDBアクセスは、通常より長くかかります。これは費用削減との意図的なトレードオフです。

## セキュリティ境界

| 対象 | Inbound | Outbound |
|---|---|---|
| ALB | Internetから80/443 | VPC内の8000 |
| ECS | ALB Security Groupから8000 | NAT Gateway経由のInternetおよびAurora |
| Aurora | ECS Security Groupから5432 | なし |

AuroraのMaster PasswordはRDSがSecrets Managerで生成・ローテーション対象として管理します。ECS Task DefinitionにはSecretの値ではなくARNだけを記録し、起動時にECS Execution Roleが取得します。

## WAF

- Core Rule Set: 一般的なWeb攻撃への基礎防御
- Amazon IP Reputation List: AWS脅威情報に基づくIP遮断
- Rate-based Rule: 1 IPにつき5分500リクエスト
- CloudWatch Logs: 7日保持、AuthorizationとCookie Headerをログから除外

Bot ControlとCAPTCHAは追加料金を避けるため初期構成から除外しています。Managed Ruleは誤検知の可能性があるため、公開後にSampled Requestsとログを確認します。

## CI/CDの権限分離

| Role | 利用元 | 主な権限 |
|---|---|---|
| GitHub App Role | GitHub `dev` Environment | ECR Push、ECS Task登録・更新・実行 |
| GitHub Terraform Role | GitHub `dev` Environment | 対象AWSサービスとRemote Stateの管理 |
| ECS Execution Role | ECS Agent | ECR Pull、Logs送信、DB Secret取得 |
| ECS Task Role | FastAPI | 現時点では追加AWS権限なし |

GitHubのOIDC Subjectでリポジトリ、Branch、Environmentを制限します。Terraform Roleは強い権限を持つため、GitHub EnvironmentのRequired reviewersを設定します。

## 初回デプロイの循環依存対策

ECS ServiceはECR内のアプリイメージを必要とします。一方、GitHub Actions用RoleとECRはTerraformで作成します。初回Terraform Apply時はServiceをDesired Count 0で作り、最初のアプリWorkflowが次を行います。

```text
ECR Push → DB Migration → ECS Task Definition更新 → Desired Count 2
```

TerraformではECS ServiceのDesired CountとTask Definitionを`ignore_changes`にし、以降のアプリバージョン管理をCD Workflowへ委譲します。

ECS Service Auto Scalingは通常時の可用性を確保するため最小2タスク、急な負荷に対応するため最大4タスクとします。Target Trackingで平均CPU使用率50%を目標にし、Scale Outは60秒、Scale Inは300秒のCooldownを設定しています。

## 本番構成へ拡張する場合

- NAT Gateway経由の通信量を分析し、必要に応じてVPC Endpointを追加する
- Aurora Readerを別AZへ追加する
- `deletion_protection`と最終Snapshotを有効にする
- dev、staging、prodでAWSアカウントとStateを分離する
- WAF RuleをCountモードで評価してからBlockへ移行する
- ALB Access Logsを専用S3へ保存する
- GuardDuty、Security Hub、Configを組み合わせる
