data "aws_rds_engine_version" "aurora_postgresql" {
  engine  = "aurora-postgresql"
  version = var.aurora_engine_version
  latest  = true
}

resource "aws_db_subnet_group" "portfolio" {
  name       = local.name
  subnet_ids = [for subnet in aws_subnet.database : subnet.id]
  tags       = { Name = local.name }
}

resource "aws_rds_cluster" "portfolio" {
  cluster_identifier = local.name
  engine             = "aurora-postgresql"
  engine_mode        = "provisioned"
  engine_version     = data.aws_rds_engine_version.aurora_postgresql.version_actual
  database_name      = "portfolio"
  master_username    = "portfolio_admin"

  manage_master_user_password = true
  storage_encrypted           = true

  db_subnet_group_name   = aws_db_subnet_group.portfolio.name
  vpc_security_group_ids = [aws_security_group.database.id]

  serverlessv2_scaling_configuration {
    min_capacity             = 0
    max_capacity             = var.aurora_max_capacity
    seconds_until_auto_pause = var.aurora_auto_pause_seconds
  }

  backup_retention_period      = 1
  preferred_backup_window      = "18:00-19:00"
  preferred_maintenance_window = "sun:19:00-sun:20:00"
  copy_tags_to_snapshot        = true

  deletion_protection = false
  skip_final_snapshot = true

  enabled_cloudwatch_logs_exports = ["postgresql"]
}

resource "aws_rds_cluster_instance" "portfolio" {
  for_each = local.database_subnets

  identifier         = "${local.name}-${each.key}"
  cluster_identifier = aws_rds_cluster.portfolio.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.portfolio.engine
  engine_version     = aws_rds_cluster.portfolio.engine_version
  availability_zone  = each.key
  promotion_tier     = each.key == local.azs[0] ? 0 : 1

  publicly_accessible          = false
  auto_minor_version_upgrade   = true
  performance_insights_enabled = false
}
