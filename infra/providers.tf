provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Repository  = "${var.github_owner}/${var.github_repository}"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_route53_zone" "portfolio" {
  name    = var.domain_name
  comment = "Public DNS zone for ${var.domain_name}"
}
