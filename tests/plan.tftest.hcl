# Plans the module against a mocked AWS provider. Run with "terraform test"
# (or "tofu test") from the repository root.

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = {
      name   = "af-south-1"
      region = "af-south-1"
    }
  }
}

variables {
  project_name                 = "example"
  environment                  = "test"
  vpc_id                       = "vpc-0123456789abcdef0"
  interface_security_group_ids = ["sg-0123456789abcdef0"]
  gateway_route_table_ids      = ["rtb-0123456789abcdef0"]
  gateway_endpoints            = { s3 = {} }
  interface_endpoints          = { ssm = {} }
}

run "one_subnet_from_known_ids" {
  command = plan

  variables {
    interface_subnet_ids = ["subnet-bbbb", "subnet-aaaa", "subnet-cccc"]
  }

  assert {
    condition     = length(aws_vpc_endpoint.interface["ssm"].subnet_ids) == 1
    error_message = "With deploy_interface_endpoints_across_azs = false, one subnet is used."
  }
}

run "all_subnets_when_across_azs" {
  command = plan

  variables {
    interface_subnet_ids                  = ["subnet-bbbb", "subnet-aaaa", "subnet-cccc"]
    deploy_interface_endpoints_across_azs = true
  }

  assert {
    condition     = length(aws_vpc_endpoint.interface["ssm"].subnet_ids) == 3
    error_message = "Across AZs, every subnet is used."
  }
}

run "subnet_ids_unknown_until_apply" {
  command = plan

  module {
    source = "./tests/unknown_subnets"
  }
}
