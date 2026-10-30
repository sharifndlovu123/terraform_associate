terraform {
  required_providers {
    random = {
      source = "hashicorp/random"
    }
  }
}

variable "prefix" {
  type = string
}

resource "random_pet" "this" {
  length = 1
}

output "message" {
  value = "${var.prefix}-${random_pet.this.id}"
}
