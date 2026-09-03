# Terraform bootstrap

## 目的

このディレクトリは、後続の Terraform 構成が Remote State を保存するための S3 バケットだけを作成します。VPC、ECS、Aurora、ALB などのアプリケーション基盤は対象外です。

bootstrap を本体から分離する理由は、Terraform 本体が利用する backend を本体自身より先に用意する必要があるためです。依存関係を明確にし、State 保管基盤のライフサイクルをアプリケーション基盤から独立させることで、誤操作の影響範囲も小さくします。

## 作成されるリソース

- Terraform State 専用の S3 バケット
- バケットの Versioning 設定
- SSE-S3（AES256）によるサーバー側暗号化設定
- S3 Public Access Block 設定
- ACL を無効化する Bucket owner enforced 設定

Versioning は、State が上書き・破損した場合に過去バージョンを復元できるようにするため有効化します。暗号化は State に含まれ得る構成情報を保存時に保護するため有効化します。bootstrap では専用 KMS キーのコストと運用を増やさず、S3 が管理するキーを使う SSE-S3（AES256）を採用します。

Public Access Block は、設定ミスによる State の公開を防ぐため、4 項目すべてを有効化します。ACL は `BucketOwnerEnforced` により無効化し、アクセス制御を IAM とバケットポリシーに統一します。また、`force_destroy = false` と Terraform の `prevent_destroy` により、State オブジェクトを含むバケットの誤削除を防ぎます。

## 実行方法

bootstrap の S3 バケットはまだ存在しないため、初回は bootstrap 自身の State をローカルで管理します。ローカル State にはリソース属性や機密情報が含まれる可能性があるため、Git へコミットしてはいけません。ルートの `.gitignore` で State とローカル変数ファイルを除外していますが、State は別途安全に保管してください。

AWS 認証情報はコードに記述せず、AWS CLI のプロファイル、環境変数、IAM ロールなど、AWS Provider の標準 credential chain から取得します。

```bash
cd bootstrap
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvars の state_bucket_name をグローバルに一意な名前へ変更する

terraform init
terraform fmt -check
terraform validate
terraform plan -out=bootstrap.tfplan
# plan の内容を必ず確認してから、明示的な判断のもとで apply する
terraform apply bootstrap.tfplan
```

## 後続構成での S3 backend 設定

bootstrap 適用後、出力されたバケット名を後続 Terraform 構成の backend に設定します。backend ブロックでは変数を参照できないため、環境ごとの backend 設定ファイルを使う方法も検討してください。

```hcl
terraform {
  backend "s3" {
    bucket       = "作成したバケット名"
    key          = "dev/terraform.tfstate"
    region       = "ap-northeast-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

その後、後続構成のディレクトリで `terraform init` を実行します。既存のローカル State を移行する場合は、Terraform が表示する移行確認を慎重に確認してください。

State locking には S3 backend の `use_lockfile = true` を使用します。DynamoDB のロックテーブルは作成しません。ロックファイルの読み書きに必要な S3 権限も、後続の実行ロールへ付与してください。

`terraform apply` の前には必ず `terraform plan` を実行し、作成・変更・削除されるリソースが意図どおりであることを確認してください。
