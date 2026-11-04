terraform {
  # Terraform CLI itself: any 1.x from 1.5.0 up, never 2.0
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    # ~> 3.6   means  >= 3.6.0, < 4.0.0   (minor and patch may move, major may not)
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }

    # ~> 3.2.0 means  >= 3.2.0, < 3.3.0   (patch only)
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.0"
    }

    # = pins one exact release
    local = {
      source  = "hashicorp/local"
      version = "= 2.5.3"
    }
  }
}
