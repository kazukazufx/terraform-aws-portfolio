locals {
  name = "${var.project_name}-${var.environment}"
  azs  = slice(data.aws_availability_zones.available.names, 0, 2)

  public_subnets = {
    for index, az in local.azs : az => cidrsubnet(var.vpc_cidr, 8, index)
  }
  private_app_subnets = {
    for index, az in local.azs : az => cidrsubnet(var.vpc_cidr, 8, index + 2)
  }
  database_subnets = {
    for index, az in local.azs : az => cidrsubnet(var.vpc_cidr, 8, index + 10)
  }

  repository_full_name = "${var.github_owner}/${var.github_repository}"
  repository_oidc_subject = join("", [
    "repo:${var.github_owner}@${var.github_owner_id}",
    "/${var.github_repository}@${var.github_repository_id}",
    ":environment:${var.environment}",
  ])
}
