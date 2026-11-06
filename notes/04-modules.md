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
- Find modules at registry.terraform.io: filter by provider, or search partial terms (`azure compute`)
- **Verified** badge = from a HashiCorp partner and reviewed. It says nothing about quality or features: an unverified module can be excellent, a verified one can be very simple
- **HCP Terraform private registry**: share modules inside your organisation; publishing means linking a VCS provider (GitHub, GitLab, Bitbucket or Azure DevOps) and picking the repo

### Source address forms

```hcl
module "consul" {                          # public registry: <NAMESPACE>/<NAME>/<PROVIDER>
  source  = "hashicorp/consul/aws"
  version = "0.1.0"
}

module "vpc" {                             # private registry: <HOSTNAME>/<NAMESPACE>/<NAME>/<PROVIDER>
  source  = "app.terraform.io/example_corp/vpc/aws"
  version = "0.9.3"
}

module "local" { source = "./modules/app" }   # local path (no version argument)
```

- `terraform init` downloads and caches every module the config references
- Private registry access needs credentials: run `terraform login` (or put an API token in the CLI config file)

### Publishing to the public registry

- The module lives in a **public GitHub repo** named `terraform-<PROVIDER>-<NAME>` (e.g. `terraform-aws-vpc`)
- Connect the repo to the registry once, then release by pushing a **version tag** (`v1.2.0`); the registry builds docs, examples, README and version history from the repo

## Standard module structure

```text
.
├── README.md        # how it works (a nested module with a README counts as usable by others)
├── main.tf          # entry point
├── variables.tf     # inputs
├── outputs.tf       # outputs
├── LICENSE
├── modules/         # optional nested modules (no README = internal use only)
│   ├── nestedA/
│   └── nestedB/
└── examples/        # runnable usage examples
    └── exampleA/main.tf
```

- The root module is the directory you run Terraform in; nested modules live under `modules/`

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
