
locals {
  aws_region = data.aws_region.current.region

  endpoint_name_prefix = "${var.project_name}-${var.environment}-vpc-endpoint"


  # A set has no index, so the single-subnet case takes the first element of
  # the set as a list: the lowest subnet ID, which is stable across plans.
  endpoint_subnet_ids = (
    var.deploy_interface_endpoints_across_azs
    ? var.interface_subnet_ids
    : toset([tolist(var.interface_subnet_ids)[0]])
  )


  common_tags = merge(
    var.tags,
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )

  gateway_endpoints = {
    for service, config in var.gateway_endpoints :
    service => {
      policy = config.policy
    }
  }

  interface_endpoints = {
    for service, config in var.interface_endpoints :
    service => {
      private_dns_enabled = config.private_dns_enabled
      policy              = config.policy
    }
  }
}