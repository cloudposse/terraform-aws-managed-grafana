locals {
  enabled                   = module.this.enabled
  prometheus_policy_enabled = local.enabled && var.prometheus_policy_enabled
}

resource "aws_grafana_workspace" "this" {
  count = local.enabled ? 1 : 0

  name        = module.this.id
  description = "Amazon Managed Grafana for ${module.this.id}"

  # TODO make all of these variables in submodule with these defaults
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["AWS_SSO"]
  permission_type          = "SERVICE_MANAGED"
  role_arn                 = aws_iam_role.this[0].arn
  data_sources             = []

  dynamic "vpc_configuration" {
    for_each = var.vpc_configuration != null ? [1] : []
    content {
      security_group_ids = var.vpc_configuration.security_group_ids
      subnet_ids         = var.vpc_configuration.subnet_ids
    }
  }

  tags = module.this.tags
}

resource "aws_iam_role" "this" {
  count = local.enabled ? 1 : 0

  name = module.this.id

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "grafana.amazonaws.com"
        }
      },
    ]
  })

  # Allow this role to assume other roles.
  # Used for cross-account access
  dynamic "inline_policy" {
    for_each = length(var.additional_allowed_roles) > 0 ? [1] : []
    content {
      name = "${module.this.id}-allowed-roles"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Action   = ["sts:AssumeRole"]
            Effect   = "Allow"
            Resource = var.additional_allowed_roles
          },
        ]
      })
    }
  }

  dynamic "inline_policy" {
    for_each = local.prometheus_policy_enabled ? [1] : []
    content {
      name   = "${module.this.id}-aps"
      policy = data.aws_iam_policy_document.aps[0].json
    }
  }
}

# See "Amazon Managed Service for Prometheus"
# https://docs.aws.amazon.com/grafana/latest/userguide/AMG-manage-permissions.html
data "aws_iam_policy_document" "aps" {
  count = local.prometheus_policy_enabled ? 1 : 0
  statement {
    actions = [
      "aps:ListWorkspaces",
      "aps:DescribeWorkspace",
      "aps:QueryMetrics",
      "aps:GetLabels",
      "aps:GetSeries",
      "aps:GetMetricMetadata"
    ]
    resources = ["*"]
  }
}
