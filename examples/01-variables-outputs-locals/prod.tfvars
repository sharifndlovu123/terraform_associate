# Not autoloaded, pass it explicitly: terraform apply -var-file=prod.tfvars
# -var-file beats terraform.tfvars, so these override its values.
environment = "prod"

# Replaces the whole list from terraform.tfvars, it does not merge with it
worlds = ["barsoom", "alloom"]
