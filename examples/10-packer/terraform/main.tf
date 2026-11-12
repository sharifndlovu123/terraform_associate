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

data "aws_ami" "example" {
  executable_users = ["self"]
  most_recent      = true
  name_regex       = "^my-server-httpd" # matches the ami_name Packer used, the newest match wins
  # for numbered builds (ami_name = "myami-001", "myami-002", ...) use: "^myami-\\d{3}"
  owners           = ["self"]
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.example.id
  instance_type = "t2.micro"

  tags = { Name = "from-packer-image" }
}
