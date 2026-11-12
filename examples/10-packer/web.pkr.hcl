# Packer template: bakes an EBS-backed AMI. Example only, `packer build` needs AWS credentials
# and creates a real AMI (costs money). `packer init` + `packer validate` work without.

packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1.3"
    }
  }
}

variable "ami_id" {
  type    = string
  default = "ami-01e78c5619c5e68b4" # base image to start from (region specific, replace with one in your region)
}

locals {
  app_name = "httpd"
}

# source = where and what kind of image to build
source "amazon-ebs" "httpd" {
  ami_name      = "my-server-${local.app_name}"
  instance_type = "t2.micro"
  region        = "us-west-2"
  source_ami    = var.ami_id
  ssh_username  = "ec2-user"

  tags = {
    Env  = "DEMO"
    Name = "my-server-${local.app_name}"
  }
}

# build = what to do to the machine, using provisioners
build {
  sources = ["source.amazon-ebs.httpd"]

  provisioner "shell" {
    script = "script/script.sh"
  }

  # post-processors run after the image is built (upload, repackage, notify)
  post-processor "shell-local" {
    inline = ["echo image built"]
  }
}
