# Default provider configuration
provider "random" {}

# Alias: a second configuration of the same provider
provider "random" {
  alias = "alt"
}

# Resource using the default provider
resource "random_pet" "root" {
  length = 2
}

# Resource picking the aliased provider
resource "random_pet" "aliased" {
  provider = random.alt
  length   = 2
}

# Local module; "providers" passes the aliased config in as the module's default "random"
module "greeting" {
  source = "./modules/greeting"
  prefix = "greeting"

  providers = {
    random = random.alt
  }
}
