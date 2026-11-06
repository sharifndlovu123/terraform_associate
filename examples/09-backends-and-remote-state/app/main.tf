# Consumer stack: reads the root outputs of the network stack's state.
# Needs ../network applied first.
data "terraform_remote_state" "network" {
  backend = "local"
  config = {
    path = "${path.module}/../network/state/network.tfstate"
  }
}

# Same data source against HCP Terraform instead of a local file:
#   data "terraform_remote_state" "network" {
#     backend = "remote"
#     config = {
#       organization = "my-org"
#       workspaces = { name = "network-prod" }
#     }
#   }

# Optional object attributes: `b` may be omitted (null), `c` falls back to 5.
variable "settings" {
  type = object({
    a = string
    b = optional(string)
    c = optional(number, 5)
  })
  default = { a = "x" }
}

output "subnet_from_network_stack" {
  value = data.terraform_remote_state.network.outputs.subnet_id
}

output "settings" {
  value = var.settings
}
