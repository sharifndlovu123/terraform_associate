# Terragrunt wrapper config (a terragrunt.hcl, not Terraform). Example only: NOT run, the
# terragrunt CLI was not installed here. Run with: terragrunt init / plan / apply

# where the Terraform module comes from. tfr:/// is the registry shorthand
# (the extra slash is required): same as registry.terraform.io/terraform-aws-modules/vpc/aws 3.5.0
terraform {
  source = "tfr:///terraform-aws-modules/vpc/aws?version=3.5.0"
}

# write provider.tf before every run: a provider block with values plain Terraform
# could not compute, and no boilerplate copied into each module
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF2
provider "aws" {
  region = "us-east-1"
}
EOF2
}

# values for the module's input variables
inputs = {
  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false
}
