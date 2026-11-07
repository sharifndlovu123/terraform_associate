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
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

# S3 bucket names are globally unique, so add a random suffix.
resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "test" {
  bucket        = "tf-assoc-test-${random_id.suffix.hex}"
  force_destroy = true # lets `terraform destroy` delete it even if it has objects

  tags = {
    Purpose = "terraform-associate-practice"
  }
}

output "bucket_name" {
  value = aws_s3_bucket.test.bucket
}
