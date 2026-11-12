# The Terraform side: an EC2 instance whose type comes from a variable.
# The Sentinel policy in ../policy checks that type (and the Name tag) at plan time.
# Example only: not applied (needs AWS + an HCP Terraform workspace).

terraform {
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

variable "instance_type" {
  type    = string
  default = "t2.micro" # try "t2.large" in the workspace to watch the policy block the run
}

# Latest Amazon Linux 2023 AMI, so no AMI ID is hard-coded
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_instance" "demo" {
  ami           = data.aws_ssm_parameter.al2023.value
  instance_type = var.instance_type

  tags = {
    Name = "sentinel-demo" # remove this line and the policy fails too
  }
}
