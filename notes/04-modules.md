# Modules

- A module is a folder of `.tf` files you call like a function: it packages a pattern so you write less and repeat fewer mistakes
- Typical payoff: a networking setup that is a dozen raw resources becomes one `module` block with a few inputs
- Sources: the public registry, a private registry, or a local path

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.2.0"
  name    = "demo"
  cidr    = "10.0.0.0/16"
}
```

## Registry

- A registry module page lists usage, inputs, outputs, dependencies, resources, examples and submodules
- **HCP Terraform private registry**: share modules inside your organisation; publishing means linking a VCS provider (GitHub, GitLab, Bitbucket or Azure DevOps) and picking the repo

## Provider aliases and modules

```hcl
# inside the module: say which aliased configs it expects
terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.replica]
    }
  }
}

# in the caller: hand the module the configs it asked for
module "network" {
  source = "./network"
  providers = {
    aws.replica = aws.eu
  }
}
```

Example: [`examples/05-modules-and-provider-alias`](../examples/05-modules-and-provider-alias)

## Gotchas
