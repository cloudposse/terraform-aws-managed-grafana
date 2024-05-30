output "workspace_id" {
  description = "The ID of the Amazon Managed Grafana workspace"
  value       = local.enabled ? aws_grafana_workspace.this[0].id : ""
}

output "workspace_arn" {
  description = "The ARN of the Amazon Managed Grafana workspace"
  value       = local.enabled ? aws_grafana_workspace.this[0].arn : ""
}

output "workspace_endpoint" {
  description = "The URL of the Amazon Managed Grafana workspace"
  value       = local.enabled ? aws_grafana_workspace.this[0].endpoint : ""
}
