# Producer stack: keeps its state in a custom local path and publishes an output.
# Run this first: terraform -chdir=network init && terraform -chdir=network apply
terraform {
  backend "local" {
    path = "state/network.tfstate" # default would be ./terraform.tfstate
  }
}

resource "terraform_data" "vpc" {
  input = "vpc-0abc123"
}

output "subnet_id" {
  value = "subnet-0def456"
}

# Only root-level outputs can be read by other stacks. To expose something
# from a nested module, pass it through a root output:
#   output "app_value" { value = module.app.example }
