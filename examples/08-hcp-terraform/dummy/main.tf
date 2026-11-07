terraform {
  required_version = "1.17.0"

  cloud {

    organization = "devbridge-playground"

    workspaces {
      name = "default-workstation"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

# The bucket now comes from the demo module in the HCP Terraform private registry
# (repo: terraform-aws-demo-bucket). The module adds the random suffix itself.
module "bucket" {
  source  = "app.terraform.io/devbridge-playground/demo-bucket/aws"
  version = "~> 1.0"

  name_prefix = "tf-assoc-test"

  tags = {
    Purpose = "terraform-associate-practice"
  }
}

output "bucket_name" {
  value = module.bucket.bucket_name
}
