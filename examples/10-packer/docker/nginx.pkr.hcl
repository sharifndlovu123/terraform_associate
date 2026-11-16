# Free Packer template: bakes a local Docker image. No cloud account, no cost, only Docker.
# Same workflow as ../web.pkr.hcl (source -> build -> provisioner -> post-processor), different builder.

packer {
  required_plugins {
    docker = {
      source  = "github.com/hashicorp/docker"
      version = "~> 1.1"
    }
  }
}

variable "base_image" {
  type    = string
  default = "nginx:1.27-alpine" # pulled from Docker Hub, the Docker equivalent of source_ami
}

locals {
  app_name = "nginx"
}

# source = where and what kind of image to build (here a local container instead of an EC2 instance)
source "docker" "nginx" {
  image  = var.base_image
  commit = true # save the container as an image (export = "file.tar" would write a tarball instead)

  # Packer runs the build container with --entrypoint=/bin/sh, and commit keeps that.
  # Put the base image's entrypoint/cmd back, or the image starts a shell instead of nginx.
  changes = [
    "ENTRYPOINT [\"/docker-entrypoint.sh\"]",
    "CMD [\"nginx\", \"-g\", \"daemon off;\"]",
    "EXPOSE 80",
    "LABEL built-by=packer",
  ]
}

build {
  sources = ["source.docker.nginx"]

  provisioner "shell" {
    inline_shebang = "/bin/sh -e" # alpine has no bash
    inline = [
      "echo '<h1>Baked by Packer</h1>' > /usr/share/nginx/html/index.html",
    ]
  }

  # docker-tag names the committed image, like ami_name does for the AMI
  post-processor "docker-tag" {
    repository = "my-server-${local.app_name}"
    tags       = ["latest"]
  }
}
