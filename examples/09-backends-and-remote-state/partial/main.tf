# Partial backend configuration: settings that are dynamic or sensitive stay out
# of the code and arrive at init time.
#   terraform init -backend-config=backend.hcl
terraform {
  backend "local" {}
}
