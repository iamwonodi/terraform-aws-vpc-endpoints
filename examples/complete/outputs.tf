output "gateway_endpoint_ids" {
  description = "IDs of the created gateway VPC endpoints."
  value       = module.vpc_endpoints.gateway_endpoint_ids
}

output "interface_endpoint_ids" {
  description = "IDs of the created interface VPC endpoints."
  value       = module.vpc_endpoints.interface_endpoint_ids
}

output "interface_endpoint_dns_entries" {
  description = "DNS entries exposed by the created interface VPC endpoints."
  value       = module.vpc_endpoints.interface_endpoint_dns_entries
}