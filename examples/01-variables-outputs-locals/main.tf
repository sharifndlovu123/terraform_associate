locals {
  service_name = "billing-api"
  owner        = "Platform Team"
}

# Locals can reference other locals
locals {
  common_tags = {
    Service     = local.service_name
    Owner       = local.owner
    Environment = var.environment
  }
}

resource "terraform_data" "app" {
  input = {
    tags  = local.common_tags
    zones = var.availability_zone_names
    ports = var.docker_ports
  }
}
