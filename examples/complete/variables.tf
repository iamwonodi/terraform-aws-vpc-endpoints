variable "project_name" {
  type        = string
  description = "Project name used for endpoint resource naming and tags."
}

variable "environment" {
  type        = string
  description = "Deployment environment such as development, staging, or production."
}

variable "vpc_id" {
  type        = string
  description = "VPC where the endpoints will be created."
}

variable "interface_subnet_ids" {
  type        = set(string)
  description = "Subnets available for interface endpoint network interfaces."
}

variable "deploy_interface_endpoints_across_azs" {
  type        = bool
  description = "Create interface endpoint network interfaces in every supplied subnet when true; otherwise use only the first subnet."
  default     = false
}

variable "interface_security_group_ids" {
  type        = list(string)
  description = "Security groups attached to interface endpoint network interfaces."
  default     = []
}

variable "gateway_route_table_ids" {
  type        = set(string)
  description = "Route tables associated with gateway endpoints."
  default     = []
}

variable "gateway_endpoints" {
  type = map(object({
    policy = optional(string)
  }))

  description = "Gateway endpoint services and optional endpoint policies."

  default = {
    s3 = {}
  }
}

variable "interface_endpoints" {
  type = map(object({
    private_dns_enabled = optional(bool, true)
    policy              = optional(string)
  }))

  description = "Interface endpoint services and their optional private DNS and endpoint policy settings."

  default = {
    "ecr.api"      = {}
    "ecr.dkr"      = {}
    ssm            = {}
    ssmmessages    = {}
    ec2messages    = {}
    secretsmanager = {}
    kms            = {}
  }
}

variable "tags" {
  type        = map(string)
  description = "Additional tags applied to endpoint resources."
  default     = {}
}