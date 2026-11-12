# Example only: describes real AWS resources, not meant to be applied here.
# `terraform init` + `terraform validate` work without credentials.

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

locals {
  bucket_name = "demo-terraform-associate-bucket-0001" # bucket names are global: change it
}

resource "aws_s3_bucket" "demo" {
  bucket = local.bucket_name

  tags = { Purpose = "study-example" }
}

# Block all public access (do this before attaching any policy)
resource "aws_s3_bucket_public_access_block" "demo" {
  bucket                  = aws_s3_bucket.demo.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "demo" {
  bucket = aws_s3_bucket.demo.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "demo" {
  bucket = aws_s3_bucket.demo.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# A bucket has exactly ONE policy. Merge several documents into it with
# source_policy_documents (see policies.tf for each statement).
data "aws_iam_policy_document" "combined" {
  source_policy_documents = [
    data.aws_iam_policy_document.https_only.json,
    data.aws_iam_policy_document.deny_unencrypted_uploads.json,
    data.aws_iam_policy_document.read_only_role.json,
  ]
}

resource "aws_s3_bucket_policy" "demo" {
  bucket = aws_s3_bucket.demo.id
  policy = data.aws_iam_policy_document.combined.json

  # the public access block must exist first, otherwise the two calls can race
  depends_on = [aws_s3_bucket_public_access_block.demo]
}

output "bucket_arn" {
  value = aws_s3_bucket.demo.arn
}
