# ADR-0002: インフラ反映とアプリデプロイを分離する

- 状態: 採用
- 対象: GitHub Actions

## 文脈

Terraformによる基盤変更と、頻度の高いアプリケーション更新では、必要な権限、失敗時の影響、承認方法が異なる。1つの強いRoleとWorkflowへ統合すると、日常的なアプリ更新に不要なインフラ変更権限を与えることになる。

## 決定

- Terraform用Roleとアプリデプロイ用Roleを分離する。
- 両RoleともGitHub OIDCの一時認証を使う。
- Terraform Applyは手動起動とEnvironment承認を必要とする。
- アプリは変更不能なコミットSHA Tagで配布する。
- DB migration成功後にだけECS Serviceを更新する。

## 結果

権限と変更経路が明確になり、失敗範囲を狭められる。一方でWorkflowが増えるため、READMEとRunbookで運用方法を維持する必要がある。
