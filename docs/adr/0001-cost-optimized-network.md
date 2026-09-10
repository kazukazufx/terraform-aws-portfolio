# ADR-0001: デモ環境ではECS TaskへPublic IPを割り当てる

- 状態: ADR-0003により置換
- 対象: `dev` ポートフォリオ環境

現在の決定は [ADR-0003](0003-private-ecs-with-nat-gateways.md) を参照する。

## 文脈

Private SubnetのFargateからECR、CloudWatch Logs、Secrets Managerへ接続するには、NAT Gatewayまたは複数のVPC Endpointが必要になる。低トラフィックの個人作品では、その固定費が全体に占める割合が大きい。

## 決定

ECS TaskをPublic Subnetへ配置してPublic IPを割り当てる。ただしInboundはALB Security GroupからPort 8000への通信だけを許可し、Taskへインターネットから直接接続できないようにする。AuroraはRouteを持たないDatabase Subnetに置き、Public Accessを無効にする。

## 結果

- NAT Gatewayの固定費を省ける。
- TaskにPublic IPが付くため、商用本番の推奨構成との差分を説明する必要がある。
- 本番拡張時はECSをPrivate Subnetへ移し、可用性要件に応じてNAT GatewayまたはVPC Endpointを採用する。
