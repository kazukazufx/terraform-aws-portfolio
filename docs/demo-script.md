# 3分デモ台本

## 0:00〜0:25 課題と成果

画面に公開サイトを表示する。

> 就職活動用サイトを題材に、設計、構築、デプロイ、監視まで再現できるAWS基盤を作りました。アプリの機能量ではなく、安全な変更と運用を主なテーマにしています。

## 0:25〜0:55 構成

READMEの構成図を表示する。

> ALBとサブネットを2つのAZへ配置し、ECSへの通信はALBからだけ、Auroraへの通信はECSからだけ許可しています。Terraform Stateは暗号化、Versioning、Lockを有効にしたS3へ保存します。

## 0:55〜1:25 IaCとセキュリティ

Terraformの `network.tf`、`security.tf`、`iam.tf` を順に表示する。

> AWSリソースはTerraformで管理しています。DBパスワードはRDSとSecrets Managerに管理させ、コードやGitHub Secretsへ保存しません。GitHub ActionsはOIDCによる一時認証を使い、リポジトリIDとEnvironmentまで信頼条件を絞っています。

## 1:25〜1:55 CI/CD

GitHub Actionsの成功画面を表示する。

> Pull Requestではアプリテスト、Terraformの検証とmock testを実行します。デプロイ時はコミットSHAを付けた変更不能なImageをECRへPushし、DB migrationが成功した場合だけECS Serviceを更新します。

## 1:55〜2:25 監視と障害演習

CloudWatch Alarm、ECS Service Events、障害演習記録を表示する。

> ECS Taskを意図的に停止し、ECSによる再作成とALB Targetの復旧を確認しました。異常なTargetとALB 5xxをCloudWatch Alarmで検知し、対応手順をRunbookに残しています。

## 2:25〜2:50 コスト判断

`docs/cost-estimate.md` を表示する。

> ECS Taskは2つのPrivate App Subnetへ配置し、Public IPを持たせていません。各AZのNAT Gatewayで外向き通信の可用性を確保しています。固定費とのトレードオフがあるため、面接前後の約1週間だけ構築し、Auroraの自動停止、ログ保持期間、Budget、Terraform Destroyで費用を管理します。

## 2:50〜3:00 締め

> 構築できるだけでなく、変更、検知、復旧、削除までを一つの成果物として設計しました。詳細な判断と再現手順はREADMEから確認できます。

## 録画チェックリスト

- 氏名とGitHub URLを `app/content.py` で本人用に変更する
- AWSアカウントID、メールアドレス、Secretを映さない
- ブラウザの通知と不要なタブを閉じる
- Actionsの成功履歴と障害演習Evidenceを事前に用意する
- 1080pで録画し、字幕を付ける
