# Points this config at HCP Terraform (formerly Terraform Cloud).
# terraform validate works offline. terraform init needs `terraform login` and a real organisation.
terraform {
  cloud {
    organization = "my-org" # replace with your HCP Terraform organisation

    workspaces {
      name = "network-prod" # one fixed workspace
    }

    # Alternative: select several workspaces by tag and/or project instead of one name.
    # (a cloud block takes either `name` or `tags`/`project`; checked with terraform validate)
    #
    # workspaces {
    #   project = "platform"
    #   tags    = ["network", "prod"]
    # }
  }
}
