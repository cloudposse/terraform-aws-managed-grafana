locals {
  enabled                          = module.this.enabled
  prometheus_policy_enabled        = local.enabled && var.prometheus_policy_enabled
  sso_role_association_enabled     = local.enabled && contains(var.authentication_providers, "AWS_SSO")
  additional_allowed_roles_enabled = local.enabled && length(var.additional_allowed_roles) > 0
}

resource "aws_grafana_workspace" "this" {
  count = local.enabled ? 1 : 0

  name        = module.this.id
  description = "Amazon Managed Grafana for ${module.this.id}"

  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = var.authentication_providers
  permission_type          = var.permission_type
  role_arn                 = aws_iam_role.this[0].arn
  data_sources             = var.data_sources

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
    for_each = local.additional_allowed_roles_enabled ? [1] : []
    content {
      name = module.additional_allowed_role_label.id
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
      name   = module.prometheus_policy_label.id
      policy = data.aws_iam_policy_document.aps[0].json
    }
  }
}

module "additional_allowed_role_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  enabled = local.additional_allowed_roles_enabled

  attributes = ["allowed-roles"]

  context = module.this.context
}

module "prometheus_policy_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  enabled = local.prometheus_policy_enabled

  attributes = ["aps"]

  context = module.this.context
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

resource "aws_grafana_role_association" "sso" {
  for_each = local.sso_role_association_enabled ? {
    for association in var.sso_role_associations : association.role => association
  } : {}

  role      = each.value.role
  group_ids = try(each.value.group_ids, null)
  user_ids  = try(each.value.user_ids, null)

  workspace_id = aws_grafana_workspace.this[0].id
}
