terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Needs AWS credentials to apply (env vars, a profile or SSO). Everything here is free-tier safe:
# VPC, subnets, internet gateway, route table and security group carry no hourly charge.
provider "aws" {
  region = local.region

  default_tags {
    tags = local.tags
  }
}
