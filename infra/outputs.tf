output "website_url" {
  description = "ポートフォリオURL"
  value       = "https://${var.domain_name}"
}

output "route53_name_servers" {
  description = "ドメイン管理会社に設定するRoute 53のネームサーバー"
  value       = aws_route53_zone.portfolio.name_servers
}

output "ecr_repository_url" {
  description = "アプリケーションイメージのECR URL"
  value       = aws_ecr_repository.app.repository_url
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.portfolio.name
}

output "ecs_service_name" {
  value = aws_ecs_service.app.name
}

output "github_app_role_arn" {
  description = "GitHub Actionsのアプリデプロイ用ロール"
  value       = aws_iam_role.github_app.arn
}

output "github_terraform_role_arn" {
  description = "GitHub ActionsのTerraform用ロール"
  value       = aws_iam_role.github_terraform.arn
}

output "database_endpoint" {
  description = "Aurora Writer Endpoint"
  value       = aws_rds_cluster.portfolio.endpoint
}

output "database_engine_version" {
  description = "選択されたAurora PostgreSQLバージョン"
  value       = data.aws_rds_engine_version.aurora_postgresql.version_actual
}

output "public_subnet_ids" {
  value = [for subnet in aws_subnet.public : subnet.id]
}

output "ecs_security_group_id" {
  value = aws_security_group.ecs.id
}
