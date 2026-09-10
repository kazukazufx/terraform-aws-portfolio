# ADR-0003: ECSをPrivate Subnetへ配置しAZごとにNAT Gatewayを置く

- 状態: 採用
- 対象: `dev` ポートフォリオ環境
- 置換対象: ADR-0001

## 文脈

ADR-0001では固定費を抑えるため、ECS TaskをPublic Subnetへ配置し、Security GroupでALBからの通信だけを許可した。その後、実際にAWS環境を稼働させる期間を面接前後の約1週間に限定できる見通しとなり、NAT Gatewayの固定費を許容できるようになった。

ポートフォリオでは、商用環境に近いネットワーク分離と、AZ障害を考慮した外向き通信経路を示したい。

## 決定

- 各AZにECS専用のPrivate App Subnetを作成する。
- Fargate TaskへPublic IPを割り当てない。
- 各AZのPublic SubnetにElastic IP付きNAT Gatewayを1台配置する。
- 各Private App Subnetは同じAZのNAT Gatewayをデフォルトルートにする。
- Auroraは外部向けデフォルトルートを持たないDatabase Subnetに維持する。
- インターネットからの入口は引き続きPublic ALBだけに限定する。

## 結果

- ECS TaskがPublic IPを持たず、インターネットから直接到達できない。
- 片方のAZに障害が起きても、もう一方のAZで外向き通信を継続できる。
- NAT Gateway 2台、Elastic IP、データ処理の料金が追加される。
- 費用を抑えるため、環境は約1週間だけ公開し、終了後にTerraformで削除する。
