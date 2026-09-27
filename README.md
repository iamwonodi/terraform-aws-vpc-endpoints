# Terraform AWS VPC Endpoints Module

Reusable Terraform module for provisioning AWS VPC endpoints for workloads that need private access to AWS services without requiring internet connectivity.

The module supports both:

* Gateway VPC endpoints
* Interface VPC endpoints
* Optional endpoint policies
* Optional private DNS for interface endpoints
* Single-subnet interface endpoint deployment
* Multi-AZ interface endpoint deployment
* Caller-supplied security groups
* Caller-supplied resource tags

## Architecture

```text
                         AWS VPC
                           |
            +--------------+--------------+
            |                             |
       Gateway Endpoints             Interface Endpoints
            |                             |
       Route Tables                 Subnet ENIs
            |                             |
        +---+---+              +----------+----------+
        |       |              |          |          |
       S3     DynamoDB        AZ-A       AZ-B       AZ-C
                                  |
                           Security Group
                                  |
                         Private AWS Services
```

Gateway endpoints use VPC route tables and do not create network interfaces.

Interface endpoints create Elastic Network Interfaces in the selected subnets and use private DNS to provide private service access.

## Supported Endpoint Configuration

The module does not hard-code a fixed set of AWS services. The caller determines which services are required through the `gateway_endpoints` and `interface_endpoints` variables.

For example:

```hcl
gateway_endpoints = {
  s3 = {}
}

interface_endpoints = {
  "ecr.api"      = {}
  "ecr.dkr"      = {}
  ssm            = {}
  ssmmessages    = {}
  ec2messages    = {}
  secretsmanager = {}
  kms            = {}
}
```

## Interface Endpoint Placement

Interface endpoints require one or more subnets.

The `deploy_interface_endpoints_across_azs` variable controls how many of the supplied subnets are used.

### Single-subnet deployment

```hcl
deploy_interface_endpoints_across_azs = false
```

Only the first subnet in `interface_subnet_ids` is used.

This reduces endpoint ENI and hourly endpoint costs.

The trade-off is that workloads in other Availability Zones access the endpoint across the VPC instead of using a local endpoint ENI.

### Multi-AZ deployment

```hcl
deploy_interface_endpoints_across_azs = true
```

An interface endpoint network interface is created in every supplied subnet.

For example:

```hcl
interface_subnet_ids = [
  "subnet-aaa",
  "subnet-bbb",
  "subnet-ccc"
]

deploy_interface_endpoints_across_azs = true
```

This creates endpoint ENIs in all three subnets.

Multi-AZ deployment provides better locality and Availability Zone resilience but increases endpoint cost because interface endpoints are billed per endpoint ENI/AZ and data processed.

## Gateway Endpoints

Gateway endpoints are associated with route tables:

```hcl
gateway_route_table_ids = [
  "rtb-12345678",
  "rtb-87654321"
]
```

Example:

```hcl
gateway_endpoints = {
  s3 = {}
}
```

Gateway endpoints are commonly used for services such as Amazon S3.

## Interface Endpoints

Interface endpoints are configured using:

```hcl
interface_endpoints = {
  "ecr.api" = {}
  "ecr.dkr" = {}
  ssm = {}
  ssmmessages = {}
  ec2messages = {}
  secretsmanager = {}
  kms = {}
}
```

Private DNS is enabled by default:

```hcl
interface_endpoints = {
  "ecr.api" = {
    private_dns_enabled = true
  }
}
```

It can be disabled for an individual endpoint when required:

```hcl
interface_endpoints = {
  "ecr.api" = {
    private_dns_enabled = false
  }
}
```

## Endpoint Policies

Endpoint policies are optional.

If no policy is supplied, the module passes `null` to AWS and the endpoint uses its AWS-defined default behavior.

A policy can be supplied when access needs to be restricted.

Example:

```hcl
interface_endpoints = {
  secretsmanager = {
    policy = jsonencode({
      Version = "2012-10-17"

      Statement = [
        {
          Effect    = "Allow"
          Principal = "*"
          Action    = [
            "secretsmanager:GetSecretValue"
          ]
          Resource = "*"
        }
      ]
    })
  }
}
```

The caller owns the policy definition.

## Interface Endpoint Security Groups

Interface endpoints require security groups:

```hcl
interface_security_group_ids = [
  aws_security_group.vpc_endpoints.id
]
```

The security group should allow the required workloads to establish HTTPS connections to the endpoint network interfaces.

A common configuration is:

```text
Workload Security Group
        |
        | TCP 443
        v
VPC Endpoint Security Group
        |
        v
AWS Interface Endpoint
```

The endpoint security group should normally allow inbound TCP/443 from the security groups or CIDR ranges that contain the workloads requiring the endpoint.

## Example Usage

```hcl
module "vpc_endpoints" {
  source = "git::https://github.com/iamwonodi/terraform-aws-vpc-endpoints.git?ref=v1.0.1"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc_base.vpc_id

  interface_subnet_ids = module.vpc_base.isolated_subnet_ids

  deploy_interface_endpoints_across_azs = false

  interface_security_group_ids = [
    module.vpc_endpoints_sg.security_group_id
  ]

  gateway_route_table_ids = module.vpc_base.private_route_table_ids

  gateway_endpoints = {
    s3 = {}
  }

  interface_endpoints = {
    "ecr.api" = {}
    "ecr.dkr" = {}
    ssm = {}
    ssmmessages = {}
    ec2messages = {}
    secretsmanager = {}
    kms = {}
  }

  tags = {
    Component = "vpc-endpoints"
  }
}
```

## Variables

| Variable                                | Type           | Default | Description                                                                         |
| --------------------------------------- | -------------- | ------- | ----------------------------------------------------------------------------------- |
| `project_name`                          | `string`       | —       | Project name used for endpoint naming and tagging.                                  |
| `environment`                           | `string`       | —       | Deployment environment.                                                             |
| `vpc_id`                                | `string`       | —       | VPC where endpoints are created.                                                    |
| `interface_subnet_ids`                  | `set(string)`  | `[]`    | Subnets available for interface endpoint ENIs.                                      |
| `deploy_interface_endpoints_across_azs` | `bool`         | `false` | Controls whether interface endpoints use the first subnet or every supplied subnet. |
| `interface_security_group_ids`          | `list(string)` | `[]`    | Security groups attached to interface endpoint ENIs.                                |
| `gateway_route_table_ids`               | `set(string)`  | `[]`    | Route tables associated with gateway endpoints.                                     |
| `gateway_endpoints`                     | `map(object)`  | `{}`    | Gateway services and optional policies.                                             |
| `interface_endpoints`                   | `map(object)`  | `{}`    | Interface services with private DNS and optional policies.                          |
| `tags`                                  | `map(string)`  | `{}`    | Additional resource tags.                                                           |

## Outputs

### `gateway_endpoint_ids`

Map of gateway endpoint service names to endpoint IDs.

### `interface_endpoint_ids`

Map of interface endpoint service names to endpoint IDs.

### `interface_endpoint_dns_entries`

Map containing the DNS entries associated with each interface endpoint.

## Example Directory

The repository contains a complete usage example under:

```text
examples/
└── complete/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

The example demonstrates configuring both gateway and interface endpoints.

## Cost Considerations

Gateway endpoints do not have the same hourly per-endpoint cost model as interface endpoints.

Interface endpoints create ENIs and incur endpoint-related hourly and data-processing charges.

Therefore:

```text
Single subnet
    ↓
Lower endpoint cost
    ↓
Less AZ-local endpoint availability

Multiple AZs
    ↓
More endpoint ENIs
    ↓
Higher cost
    ↓
Better AZ locality and resilience
```

For highly restrictive isolated workloads, a single endpoint subnet can be appropriate when cost optimization is more important than AZ-local endpoint placement.

For highly available production workloads, deploying interface endpoints across the required Availability Zones is generally preferable.

## Recommended Isolated Subnet Use

This module can be used to provide private AWS service access to resources in isolated subnets.

A typical isolated database environment may use:

```text
Isolated Database
       |
       +---- SSM
       +---- Secrets Manager
       +---- KMS
       +---- ECR API
       +---- ECR DKR
       |
       v
Interface VPC Endpoints
       |
       v
AWS Private Network
```

This allows the workload to communicate with required AWS services without requiring a public IP address.

For container workloads that pull images from Amazon ECR, both `ecr.api` and `ecr.dkr` should normally be configured, along with the supporting endpoints required by the workload.

## Requirements

* Terraform >= 1.5
* AWS provider compatible with the version constraints defined in `versions.tf`
* An existing VPC
* Existing subnets for interface endpoints
* Existing route tables for gateway endpoints
* Existing security groups for interface endpoints when interface endpoints are configured

## Validation

Before committing the module:

```powershell
terraform fmt -recursive
terraform init
terraform validate
terraform test
```

`terraform test` plans the module against a mocked AWS provider (no credentials needed), including with subnet IDs that are unknown until apply.

The complete example can be validated independently:

```powershell
cd examples/complete

terraform init
terraform validate
terraform plan
```

## Releases

`v1.0.1` fixes two problems in `v1.0.0`:

* With `deploy_interface_endpoints_across_azs = false` (the default), the module indexed `interface_subnet_ids`, a set, which Terraform does not allow, so every plan with interface endpoints failed. It now uses the first subnet ID of the set in sorted order, which is stable between plans.
* Service names containing a dot (`ecr.api`, `ecr.dkr`) must be quoted as map keys. The complete example and the snippets in this README now quote them.

Inputs and outputs are unchanged.

## Repository Structure

```text
.
├── data.tf
├── locals.tf
├── main.tf
├── outputs.tf
├── variables.tf
├── versions.tf
├── .gitignore
├── README.md
└── examples/
    └── complete/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## Module Design

The module intentionally leaves service selection, endpoint policies, subnet placement, security groups, and tagging under caller control.

This keeps the module reusable across different VPC architectures and environments while allowing each consuming project to determine exactly which AWS services require private connectivity.
