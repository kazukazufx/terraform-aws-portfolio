# 運用・障害対応Runbook

## 最初に確認すること

1. `https://<domain>/health` と `https://<domain>/api/status` の応答を確認する。
2. GitHub Actionsの直近のDeploy結果と、デプロイしたコミットSHAを確認する。
3. ECS Serviceのイベント、停止Taskの理由、ALB Target Healthを確認する。
4. CloudWatch Logsで同じ時刻のアプリケーションエラーを確認する。
5. 変更直後なら、直前のTask Definitionへのロールバックを優先する。

## 重要度

| レベル | 例 | 初動目標 |
|---|---|---|
| SEV-1 | サイト全面停止、データ消失の疑い | 直ちに公開停止または復旧を開始 |
| SEV-2 | 一部API停止、エラー率上昇 | 原因を切り分け、暫定復旧 |
| SEV-3 | 遅延、単発アラーム | ログとメトリクスを確認し記録 |

## ECSが正常にならない

```bash
aws ecs describe-services \
  --cluster terraform-aws-portfolio-dev \
  --services terraform-aws-portfolio-dev

aws ecs list-tasks \
  --cluster terraform-aws-portfolio-dev \
  --service-name terraform-aws-portfolio-dev \
  --desired-status STOPPED
```

- `stoppedReason` とコンテナの `reason` を確認する。
- ECRイメージ、Secrets Manager参照権限、DB接続、Health Checkを順に確認する。
- デプロイが原因の場合は、直前の正常なTask Definitionを指定してServiceを更新する。
- 復旧後、ALB Targetがhealthyになり`/health`が200を返すまで確認する。

## ALB 5xxが増えた

- `HTTPCode_ELB_5XX_Count` と `HTTPCode_Target_5XX_Count` を区別する。
- ALB側ならListener、Target Group、Target Healthを確認する。
- Target側ならアプリログと直近デプロイを確認する。
- WAFログのBlock増加も確認し、正常アクセスの誤検知かを切り分ける。

## DBへ接続できない

- `/health`はDBを確認しないため、`/api/projects`も確認する。
- Auroraが0 ACUから復帰中の場合、アプリは一定時間再試行する。
- Cluster状態、Secret、Security Group、DB migrationの結果を確認する。
- データ復旧が必要な場合は、保持中の自動Snapshotから新しいClusterへ復元し、十分に検証してから接続先を切り替える。

## 意図的な障害演習

`scripts/failure-drill.sh` は実行中Taskを1つ停止し、ECS Serviceによる自動復旧を観察する。実AWSリソースを変更するため、対象アカウントと環境を確認し、スクリプトが要求する確認文字列を設定した場合だけ実行する。

演習では以下を `docs/evidence/` に保存する。

- 実施日時と対象環境
- 停止前後のTask ID
- CloudWatch Alarmの状態遷移
- 復旧までの時間
- 想定どおりだった点、改善点

## 事後記録

障害または演習後は、影響、時系列、根本原因、暫定対応、恒久対応、検知できた点、検知できなかった点を記録する。個人を責めず、仕組みの改善に焦点を置く。
