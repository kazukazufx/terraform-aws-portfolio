mock_provider "aws" {
  override_during = plan

  mock_data "aws_availability_zones" {
    defaults = {
      names = ["ap-northeast-1a", "ap-northeast-1c"]
    }
  }

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:user/terraform-test"
      id         = "AIDATEST"
    }
  }

  mock_data "aws_rds_engine_version" {
    defaults = {
      version_actual = "17.4"
    }
  }

  mock_resource "aws_acm_certificate_validation" {
    defaults = {
      certificate_arn = "arn:aws:acm:ap-northeast-1:123456789012:certificate/00000000-0000-0000-0000-000000000000"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Effect   = "Allow"
          Action   = "sts:AssumeRole"
          Resource = "*"
        }]
      })
    }
  }

  mock_resource "aws_acm_certificate" {
    defaults = {
      arn = "arn:aws:acm:ap-northeast-1:123456789012:certificate/00000000-0000-0000-0000-000000000000"
      domain_validation_options = [
        {
          domain_name           = "portfolio.example.com"
          resource_record_name  = "_test.portfolio.example.com"
          resource_record_type  = "CNAME"
          resource_record_value = "_validation.acm-validations.aws"
        },
        {
          domain_name           = "www.portfolio.example.com"
          resource_record_name  = "_test.www.portfolio.example.com"
          resource_record_type  = "CNAME"
          resource_record_value = "_validation-www.acm-validations.aws"
        },
      ]
    }
  }
}

override_resource {
  target = aws_acm_certificate_validation.portfolio
  values = {
    certificate_arn = "arn:aws:acm:ap-northeast-1:123456789012:certificate/00000000-0000-0000-0000-000000000000"
  }
}

run "portfolio_baseline" {
  command = plan

  variables {
    domain_name          = "portfolio.example.com"
    state_bucket_name    = "portfolio-test-state"
    alert_email          = "alerts@example.com"
    github_owner         = "example-owner"
    github_repository    = "terraform-aws-portfolio"
    github_owner_id      = 123456
    github_repository_id = 789012
  }

  assert {
    condition = (
      length(aws_subnet.public) == 2 &&
      length(aws_subnet.private_app) == 2 &&
      length(aws_subnet.database) == 2
    )
    error_message = "Public, private application, and database subnets must span two Availability Zones."
  }

  assert {
    condition     = length(aws_nat_gateway.app) == 2 && length(aws_eip.nat) == 2
    error_message = "Each Availability Zone must have its own NAT Gateway and Elastic IP."
  }

  assert {
    condition     = !aws_ecs_service.app.network_configuration[0].assign_public_ip
    error_message = "ECS tasks must run without public IP addresses."
  }

  assert {
    condition = (
      one(aws_security_group.database.ingress).from_port == 5432 &&
      length(one(aws_security_group.database.ingress).security_groups) == 1 &&
      one(aws_security_group.database.ingress).cidr_blocks == null
    )
    error_message = "Aurora must accept PostgreSQL only from the ECS security group."
  }

  assert {
    condition     = aws_rds_cluster.portfolio.storage_encrypted && !aws_rds_cluster_instance.portfolio.publicly_accessible
    error_message = "Aurora storage must be encrypted and its instance must remain private."
  }

  assert {
    condition     = aws_ecs_service.app.desired_count == 0 && aws_ecs_service.app.deployment_circuit_breaker[0].rollback
    error_message = "The bootstrap service must start at zero tasks and enable automatic rollback."
  }

  assert {
    condition = (
      aws_appautoscaling_target.ecs.min_capacity == 2 &&
      aws_appautoscaling_target.ecs.max_capacity == 4 &&
      aws_appautoscaling_policy.ecs_cpu.target_tracking_scaling_policy_configuration[0].target_value == 50
    )
    error_message = "ECS must scale between two and four tasks at a 50 percent CPU target."
  }

  assert {
    condition     = aws_ecr_repository.app.image_tag_mutability == "IMMUTABLE" && aws_ecr_repository.app.image_scanning_configuration[0].scan_on_push
    error_message = "ECR images must be immutable and scanned on push."
  }

  assert {
    condition     = aws_cloudwatch_log_group.app.retention_in_days == 7 && length(aws_cloudwatch_metric_alarm.alb_unhealthy) == 1
    error_message = "Application logs and the unhealthy-target alarm must be configured."
  }

  assert {
    condition     = local.repository_oidc_subject == "repo:example-owner@123456/terraform-aws-portfolio@789012:environment:dev"
    error_message = "The GitHub OIDC subject must bind the immutable owner ID, repository ID, and environment."
  }
}

run "notifications_are_optional" {
  command = plan

  variables {
    domain_name       = "portfolio.example.com"
    state_bucket_name = "portfolio-test-state"
    alert_email       = ""
  }

  assert {
    condition     = length(aws_sns_topic.alerts) == 0 && length(aws_budgets_budget.monthly) == 0
    error_message = "Notification resources must be omitted when alert_email is empty."
  }
}
