
################################################################################
# CORE IDENTIFICATION
################################################################################

variable "project_name" {
  type        = string
  description = "Name of the project consuming the VPC endpoints module."

  validation {
    condition     = trimspace(var.project_name) != ""
    error_message = "project_name must not be empty."
  }
}

variable "environment" {
  type        = string
  description = "Deployment environment such as development, staging, or production."

  validation {
    condition     = trimspace(var.environment) != ""
    error_message = "environment must not be empty."
  }
}


################################################################################
# NETWORKING
################################################################################

variable "vpc_id" {
  type        = string
  description = "ID of the VPC where the VPC endpoints will be created."

  validation {
    condition     = trimspace(var.vpc_id) != ""
    error_message = "vpc_id must not be empty."
  }
}

variable "interface_subnet_ids" {
  type        = set(string)
  description = "Subnets where interface endpoint network interfaces will be created."
  default     = []

  validation {
    condition = (
      length(var.interface_endpoints) == 0
      ||
      length(var.interface_subnet_ids) > 0
    )

    error_message = "interface_subnet_ids must contain at least one subnet ID when interface endpoints are configured."
  }
}

variable "deploy_interface_endpoints_across_azs" {
  type        = bool
  description = "When true, creates an interface endpoint network interface in each supplied subnet. When false, creates the endpoint in only the first supplied subnet."
  default     = false
}

variable "gateway_route_table_ids" {
  type        = set(string)
  description = "Route tables that will receive routes for gateway endpoints."
  default     = []
}

variable "interface_security_group_ids" {
  type        = list(string)
  description = "Security groups attached to interface endpoint network interfaces."
  default     = []

  validation {
    condition = (
      length(var.interface_endpoints) == 0
      ||
      length(var.interface_security_group_ids) > 0
    )

    error_message = "interface_security_group_ids must contain at least one security group ID when interface endpoints are configured."
  }
}


################################################################################
# ENDPOINT SERVICES
################################################################################

variable "gateway_endpoints" {
  type = map(object({
    policy = optional(string)
  }))

  description = <<-EOT
    Gateway VPC endpoints to create.

    Example:
      {
        s3 = {
          policy = null
        }
      }

    Gateway endpoints are intended for services such as Amazon S3.
  EOT

  default = {}
}

variable "interface_endpoints" {
  type = map(object({
    private_dns_enabled = optional(bool, true)
    policy              = optional(string)
  }))

  description = <<-EOT
    Interface VPC endpoints to create.

    Example:
      {
        ecr.api = {
          private_dns_enabled = true
        }

        ecr.dkr = {
          private_dns_enabled = true
        }

        ssm = {
          private_dns_enabled = true
        }
      }

    Interface endpoints are created in the subnets supplied through
    interface_subnet_ids.
  EOT

  default = {}
}


################################################################################
# TAGGING
################################################################################

variable "tags" {
  type        = map(string)
  description = "Additional tags applied to all VPC endpoint resources."
  default     = {}
}