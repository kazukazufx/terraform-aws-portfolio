variable "aws_region" {
  description = "AWSリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "リソース名とタグに使うプロジェクト名"
  type        = string
  default     = "terraform-aws-portfolio"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,62}[a-z0-9]$", var.project_name))
    error_message = "project_nameは小文字英数字とハイフンを使った3〜64文字にしてください。"
  }
}

variable "environment" {
  description = "環境名"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environmentはdev、staging、prodのいずれかです。"
  }
}

variable "domain_name" {
  description = "外部レジストラで取得済みで、Route 53をDNSに使用するドメイン"
  type        = string
  default     = "aws-demo.blog"
}

variable "github_owner" {
  description = "GitHubユーザーまたはOrganization名"
  type        = string
  default     = "kazukazufx"
}

variable "github_repository" {
  description = "GitHubリポジトリ名"
  type        = string
  default     = "terraform-aws-portfolio"
}

variable "state_bucket_name" {
  description = "bootstrapで作成したTerraform State用S3バケット名"
  type        = string
}

variable "vpc_cidr" {
  description = "VPCのCIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "aurora_engine_version" {
  description = "Aurora PostgreSQLバージョン。nullの場合は東京リージョンで利用可能な最新バージョンを使用"
  type        = string
  default     = null
  nullable    = true
}

variable "aurora_max_capacity" {
  description = "Aurora Serverless v2の最大ACU"
  type        = number
  default     = 1

  validation {
    condition     = var.aurora_max_capacity >= 0.5 && var.aurora_max_capacity <= 16
    error_message = "aurora_max_capacityは0.5〜16で指定してください。"
  }
}

variable "aurora_auto_pause_seconds" {
  description = "Auroraが0 ACUへ自動停止するまでのアイドル秒数"
  type        = number
  default     = 600

  validation {
    condition     = var.aurora_auto_pause_seconds >= 300 && var.aurora_auto_pause_seconds <= 86400
    error_message = "aurora_auto_pause_secondsは300〜86400秒で指定してください。"
  }
}

variable "container_cpu" {
  description = "FargateタスクのCPUユニット"
  type        = number
  default     = 256
}

variable "container_memory" {
  description = "Fargateタスクのメモリ(MiB)"
  type        = number
  default     = 512
}

variable "image_tag" {
  description = "初回タスク定義のイメージタグ。ECSは最初のCI/CDまで0タスクで作成"
  type        = string
  default     = "bootstrap"
}

variable "waf_rate_limit" {
  description = "同一IPに許可する5分間の最大リクエスト数"
  type        = number
  default     = 500

  validation {
    condition     = var.waf_rate_limit >= 100
    error_message = "waf_rate_limitは100以上にしてください。"
  }
}

variable "alert_email" {
  description = "予算・監視アラートの通知先。空文字の場合は通知リソースを作らない"
  type        = string
  default     = ""
  sensitive   = true
}

variable "monthly_budget_amount" {
  description = "月間予算額"
  type        = number
  default     = 60
}

variable "monthly_budget_currency" {
  description = "AWS請求で使用している予算通貨"
  type        = string
  default     = "USD"
}
