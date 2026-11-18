# Two ways Consul meets Terraform: as a remote backend (state in Consul's KV store)
# and as a provider (manage Consul itself). Example only: needs a Consul agent at 127.0.0.1:8500.

terraform {
  backend "consul" {
    address = "127.0.0.1:8500"
    scheme  = "http"
    path    = "terraform/state/demo" # KV path where the state is stored (locking is supported)
  }

  required_providers {
    consul = {
      source  = "hashicorp/consul"
      version = "~> 2.20"
    }
  }
}

provider "consul" {
  address    = "127.0.0.1:8500"
  datacenter = "dc1"
}

# write a key into Consul's key/value store
resource "consul_keys" "app" {
  key {
    path  = "app/greeting"
    value = "hello"
  }
}
