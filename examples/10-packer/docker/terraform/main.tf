# Terraform side of the free Packer workflow: look up the image Packer built and run it.
# Needs only a local Docker daemon and the my-server-nginx:latest image from `packer build`.

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

# the socket is only HOW Terraform talks to Docker (unix:///var/run/docker.sock); the
# image is found by NAME below
provider "docker" {}

# like data "aws_ami": read-only lookup of the image Packer built. Runs on every plan/apply.
# Terraform does not build or own it: `terraform destroy` leaves it (remove it with `docker rmi`).
data "docker_image" "web" {
  # must match the docker-tag post-processor in ../nginx.pkr.hcl:
  # repository "my-server-${local.app_name}" + tag "latest"
  # (no most_recent/owners needed: a tag points to exactly one image, and a rebuild moves the tag)
  name = "my-server-nginx:latest"
}

# resource = what Terraform manages and records in state: a NEW container started from the image.
# Image name (set by Packer) and container name (set here) are separate objects, so they don't
# need to match. Packer's own build container was temporary and already deleted.
resource "docker_container" "web" {
  name  = "from-packer-image"      # any name you like
  image = data.docker_image.web.id # the image ID (sha256:...) the lookup returned

  ports {
    internal = 80
    external = 8080
  }
}

output "url" {
  value = "http://localhost:8080"
}
