module "vpc" {
  source  = "cloudposse/vpc/aws"
  version = "2.2.0"

  ipv4_primary_cidr_block = "172.16.0.0/16"

  context = module.this.context
}

module "subnets" {
  source  = "cloudposse/dynamic-subnets/aws"
  version = "2.4.2"

  availability_zones   = ["${var.region}a", "${var.region}b"]
  vpc_id               = module.vpc.vpc_id
  igw_id               = [module.vpc.igw_id]
  ipv4_cidr_block      = [module.vpc.vpc_cidr_block]
  nat_gateway_enabled  = false
  nat_instance_enabled = false

  context = module.this.context
}

module "security_group" {
  source  = "cloudposse/security-group/aws"
  version = "2.2.0"

  vpc_id = module.vpc.vpc_id

  context = module.this.context
}

module "managed_grafana" {
  source = "../.."

  prometheus_policy_enabled = true
  authentication_providers  = ["SAML"]

  vpc_configuration = {
    subnet_ids         = module.subnets.private_subnet_ids
    security_group_ids = [module.security_group.id]
  }

  context = module.this.context
}
