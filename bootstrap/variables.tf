variable "aws_region" {
  description = "AWS region in which to create the Terraform state bucket."
  type        = string
  default     = "ap-northeast-1"

  validation {
    condition     = can(regex("^[a-z]{2}(-[a-z]+)+-[0-9]+$", var.aws_region))
    error_message = "aws_region must be a valid AWS region name such as ap-northeast-1."
  }
}

variable "project_name" {
  description = "Project name used for AWS resource tags."
  type        = string
  default     = "terraform-aws-portfolio"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.project_name)) && length(var.project_name) <= 64
    error_message = "project_name must be 2-64 characters using lowercase letters, numbers, and hyphens, and must start and end with a letter or number."
  }
}

variable "environment" {
  description = "Deployment environment used for AWS resource tags."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "state_bucket_name" {
  description = "Globally unique S3 bucket name used to store Terraform state."
  type        = string

  validation {
    condition = (
      length(var.state_bucket_name) >= 3 &&
      length(var.state_bucket_name) <= 63 &&
      can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.state_bucket_name)) &&
      !can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$", var.state_bucket_name)) &&
      !strcontains(var.state_bucket_name, "..")
    )
    error_message = "state_bucket_name must be a valid, globally unique S3 bucket name (3-63 lowercase letters, numbers, periods, or hyphens)."
  }
}
