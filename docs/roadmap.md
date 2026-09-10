# 実装ロードマップ

| 段階 | 成果物 | 状態 |
|---|---|---|
| 第1段階 | VPC、2 AZ、ALB、Private ECS/Fargate、AZごとのNAT Gateway、HTTPS | 実装済み |
| 第2段階 | GitHub Actions、OIDC、Plan、Apply、アプリDeploy | 実装済み |
| 第3段階 | Aurora、Secrets Manager、WAF、監視、Budget | 実装済み |
| 第4段階 | Terraform test、障害演習、Runbook、費用試算 | 実装済み。実AWSでの演習証跡は未取得 |
| 第5段階 | 3分デモ台本と録画チェックリスト | 台本完成。本人情報設定と実環境録画は未実施 |

## 完成の定義

コードを置くだけでなく、次を満たした時点を公開版の完成とする。

- CIがすべて成功している
- 実URLへHTTPSでアクセスできる
- SNS購読確認が完了している
- 障害演習を1回実施し、復旧時間と改善点を記録している
- AWS Pricing Calculatorの見積を保存している
- Secretや個人のメールアドレスがGit履歴に含まれていない
- 3分デモ動画から秘密情報を除外できている
