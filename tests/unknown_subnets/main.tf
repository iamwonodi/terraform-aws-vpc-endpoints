# Calls the module with subnet IDs that are unknown until apply, as they are
# when the subnets are created in the same apply as the endpoints. Planned
# (never applied) by tests/plan.tftest.hcl.
terraform {
  required_providers {
    random = { source = "hashicorp/random" }
  }
}

resource "random_id" "subnet" {
  count       = 3
  byte_length = 8
}

module "endpoints" {
  source = "../.."

  project_name = "example"
  environment  = "test"
  vpc_id       = "vpc-0123456789abcdef0"

  # The raw attributes: unknown until apply.
  interface_subnet_ids         = random_id.subnet[*].b64_url
  interface_security_group_ids = ["sg-0123456789abcdef0"]
  gateway_route_table_ids      = ["rtb-0123456789abcdef0"]

  gateway_endpoints   = { s3 = {} }
  interface_endpoints = { ssm = {} }
}
