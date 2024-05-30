variable "prometheus_policy_enabled" {
  type        = bool
  description = "Set this to `true` to allow this Grafana workspace to access Amazon Managed Prometheus (AMP)."
  default     = false
}

variable "additional_allowed_roles" {
  type        = list(string)
  description = "A list of IAM Role ARNs that this Grafana IAM role will be allowed to assume. Use this to set up cross-account access."
  default     = []
}

variable "vpc_configuration" {
  type = object({
    security_group_ids = list(string)
    subnet_ids         = list(string)
  })
  description = "If defined, this map defines the VPC configuration to connect your Grafana workspace to a private network"
  default     = null
}
