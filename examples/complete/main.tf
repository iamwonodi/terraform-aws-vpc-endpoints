module "vpc_endpoints" {
  source = "../../"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = var.vpc_id

  # Interface endpoint placement
  interface_subnet_ids = var.interface_subnet_ids

  # false = first subnet only
  # true  = every supplied subnet/AZ
  deploy_interface_endpoints_across_azs = var.deploy_interface_endpoints_across_azs

  interface_security_group_ids = var.interface_security_group_ids

  gateway_route_table_ids = var.gateway_route_table_ids

  gateway_endpoints   = var.gateway_endpoints
  interface_endpoints = var.interface_endpoints

  tags = var.tags
}