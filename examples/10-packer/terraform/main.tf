# Terraform side of the Packer workflow: look up the image Packer built and launch it.
# Example only: needs AWS credentials and an AMI named my-server-httpd* to exist in your account.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

# data source = read-only lookup of an image Packer built. Runs on every plan/apply.
# Terraform never creates, changes or deletes the AMI: `terraform destroy` leaves it in place.
# A data source must return exactly ONE result, so the filters below narrow the search.
data "aws_ami" "example" {
  # only AMIs this account is allowed to launch (own + shared with us); belt-and-braces next to owners
  executable_users = ["self"]

  # each `packer build` creates a NEW AMI, so several can match. Without this the lookup
  # errors on multiple matches; with it the newest build wins
  most_recent = true

  name_regex = "^my-server-httpd" # must match the ami_name in ../web.pkr.hcl
  # for numbered builds (ami_name = "myami-001", "myami-002", ...) use: "^myami-\\d{3}"

  # SECURITY: only AMIs created by this account. Without it, someone's public AMI with a
  # matching name could be picked. Other values: ["amazon"], or an account ID such as
  # "099720109477" (Canonical, Ubuntu)
  owners = ["self"]
}

# resource = what Terraform manages and records in state. This is a NEW instance launched
# from the image; its Name tag is unrelated to the AMI name
resource "aws_instance" "web" {
  ami           = data.aws_ami.example.id
  instance_type = "t2.micro"

  tags = { Name = "from-packer-image" }
}
