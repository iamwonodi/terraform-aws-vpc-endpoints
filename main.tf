
################################################################################
# VPC ENDPOINTS
################################################################################

resource "aws_vpc_endpoint" "gateway" {
  for_each = local.gateway_endpoints

  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${local.aws_region}.${each.key}"
  vpc_endpoint_type = "Gateway"

  route_table_ids = var.gateway_route_table_ids

  policy = each.value.policy

  tags = merge(
    local.common_tags,
    {
      Name    = "${local.endpoint_name_prefix}-${each.key}"
      Service = each.key
      Type    = "Gateway"
    }
  )
}

resource "aws_vpc_endpoint" "interface" {
  for_each = local.interface_endpoints

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${local.aws_region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = local.endpoint_subnet_ids
  security_group_ids  = var.interface_security_group_ids
  private_dns_enabled = each.value.private_dns_enabled

  policy = each.value.policy

  tags = merge(
    local.common_tags,
    {
      Name    = "${local.endpoint_name_prefix}-${each.key}"
      Service = each.key
      Type    = "Interface"
    }
  )
}
