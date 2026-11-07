# Consumes the demo module from the HCP Terraform private registry.
# Not run on purpose. To try it: `terraform login`, then `terraform init` pulls the module.
terraform {
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

module "bucket" {
  # <HOSTNAME>/<ORG>/<NAME>/<PROVIDER>
  source  = "app.terraform.io/devbridge-playground/demo-bucket/aws"
  version = "~> 1.0" # only registry sources accept `version`

  name_prefix        = "registry-consumer"
  versioning_enabled = true

  tags = {
    Purpose = "terraform-associate-practice"
  }
}

output "bucket_name" {
  value = module.bucket.bucket_name
}
