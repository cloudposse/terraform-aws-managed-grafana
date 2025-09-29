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

variable "authentication_providers" {
  type        = list(string)
  description = "The authentication providers for the workspace. Valid values are `AWS_SSO`, `SAML`, or both."
  default     = ["AWS_SSO"]
}

variable "permission_type" {
  type        = string
  description = "The permission type of the workspace. If `SERVICE_MANAGED` is specified, the IAM roles and IAM policy attachments are generated automatically. If `CUSTOMER_MANAGED` is specified, the IAM roles and IAM policy attachments will not be created."
  default     = "SERVICE_MANAGED"
}

variable "sso_role_associations" {
  type = list(object({
    role      = string
    group_ids = optional(list(string))
    user_ids  = optional(list(string))
  }))
  description = "A list of role to group ID and user ID list associations for granting Amazon Grafana access. Only used if `var.authentication_providers` includes `AWS_SSO`"
  default     = []
}

variable "data_sources" {
  type        = list(string)
  description = "The data sources for the workspace. Valid values are AMAZON_OPENSEARCH_SERVICE, ATHENA, CLOUDWATCH, PROMETHEUS, REDSHIFT, SITEWISE, TIMESTREAM, XRAY"
  default     = []
}

variable "account_access_type" {
  type        = string
  description = "The account access type for the workspace. Valid values are `CURRENT_ACCOUNT` or `ALL_ACCOUNTS`"
  default     = "CURRENT_ACCOUNT"
}