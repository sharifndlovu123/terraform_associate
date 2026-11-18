# Something small to test. Uses only the built-in terraform_data resource, so the tests
# run offline with no cloud account.

variable "env" {
  type    = string
  default = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.env)
    error_message = "env must be dev, staging or prod."
  }
}

variable "instance_count" {
  type    = number
  default = 2
}

locals {
  names = [for i in range(var.instance_count) : "web-${var.env}-${i}"]
}

resource "terraform_data" "server" {
  count = var.instance_count

  input = { name = local.names[count.index] }
}

# built from a local, so it is known at plan time (a terraform_data output would not be)
output "names" {
  value = local.names
}
