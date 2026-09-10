# 費用試算

## 前提

この資料は設計比較用の概算であり、見積書ではない。リージョン、稼働時間、リクエスト、ログ量、データ量、為替、税によって変動するため、公開前に[AWS Pricing Calculator](https://calculator.aws/)で再計算する。

- 東京リージョン
- ECS Task: 0.25 vCPU / 0.5 GiB、1 Task
- Aurora Serverless v2: 0〜1 ACU、10分で自動停止
- 小規模な個人ポートフォリオの通信量
- ドメイン取得・更新費はAWS費用に含めない

## 主な費用要因

| サービス | 費用要因 | この構成での抑制策 |
|---|---|---|
| Application Load Balancer | 稼働時間、LCU | 公開期間だけ作成する |
| ECS Fargate | vCPU、メモリ、稼働時間 | 最小Taskサイズ、公開終了時に削除 |
| NAT Gateway | 2台の稼働時間、処理データ量、Public IPv4 | 面接前後の約1週間だけ作成 |
| Aurora Serverless v2 | ACU稼働時間、ストレージ、I/O | 0 ACU自動停止、最大1 ACU |
| AWS WAF | Web ACL、Rule、Request | 必要最小限のManaged Rule |
| Route 53 | Hosted Zone、DNS Query | Hosted Zoneを1つに限定 |
| CloudWatch | Logs、Metrics、Alarm | Logsを7日保持 |
| ECR | Image Storage、Scan | 最新10イメージだけ保持 |

## 仮の予算レンジ

低アクセスでAuroraが多くの時間停止する場合でも、2台のNAT Gateway、ALB、WAF、Route 53などには固定費がある。月額Budgetは費用の早期通知として維持するが、2台のNAT Gatewayを含む構成は常時公開せず、面接前後の約1週間だけ構築する。公開前にはAWS Pricing Calculatorで最新料金を再計算する。

面接期間だけ公開する、または必要時に構築して終了後に削除する運用が最も効果的な削減策となる。

## 比較した案

| 案 | 長所 | 短所 | 判断 |
|---|---|---|---|
| ECSをPrivate Subnet、AZごとにNAT Gateway | Public IPを持たずAZ障害時も外向き通信を維持できる | 低トラフィックでは固定費が大きい | 約1週間のデモ構成で採用 |
| ECSをPublic Subnet、SGでALBのみに制限 | NAT固定費を省ける | TaskにPublic IPが付く | ADR-0001では採用、現在は不採用 |
| Lambda + API Gateway | 低アクセス時に安い | コンテナ運用・ECSの訴求が弱い | 今回は不採用 |
| 静的サイト + CloudFront | 安価で堅牢 | DB、migration、ECS運用を示せない | 補助作品向け |

## 公開前後の確認

- AWS Pricing Calculatorの見積URLまたはPDFを `docs/evidence/` に保存する。
- Budget通知とSNS購読を確認する。
- 公開終了後はREADMEのDestroy手順を実行する。
- Cost ExplorerとBilling画面で、意図しないリソースが残っていないか確認する。
