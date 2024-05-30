data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "tester" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_security_groups" "tester" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

module "managed_grafana" {
  source = "../.."

  prometheus_policy_enabled = true
  authentication_providers  = ["SAML"]

  vpc_configuration = {
    subnet_ids         = data.aws_subnets.tester.ids
    security_group_ids = data.aws_security_groups.tester.ids
  }

  context = module.this.context
}
