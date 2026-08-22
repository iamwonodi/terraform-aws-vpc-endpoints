################################################################################
# GATEWAY ENDPOINT OUTPUTS
################################################################################

output "gateway_endpoint_ids" {
  description = "IDs of the gateway VPC endpoints created by the module."
  value = {
    for service, endpoint in aws_vpc_endpoint.gateway :
    service => endpoint.id
  }
}


################################################################################
# INTERFACE ENDPOINT OUTPUTS
################################################################################

output "interface_endpoint_ids" {
  description = "IDs of the interface VPC endpoints created by the module."
  value = {
    for service, endpoint in aws_vpc_endpoint.interface :
    service => endpoint.id
  }
}

output "interface_endpoint_dns_entries" {
  description = "DNS entries associated with the interface VPC endpoints."
  value = {
    for service, endpoint in aws_vpc_endpoint.interface :
    service => endpoint.dns_entry
  }
}