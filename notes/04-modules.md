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
  - **Newer**: the registry docs now call these **Partner** modules (a search filter; HashiCorp reviews them for stability and compatibility). Same idea, new name
- **HCP Terraform private registry**: share modules inside your organisation; publishing means linking a VCS provider (GitHub, GitLab, Bitbucket or Azure DevOps) and picking the repo

### Source address forms (004: 5a)

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

Non-registry sources (none of these take `version`; pin with `?ref=` instead):

| Form | Example |
|------|---------|
| GitHub (HTTPS / SSH) | `github.com/org/repo` / `git@github.com:org/repo.git` |
| Bitbucket | `bitbucket.org/org/repo` |
| Any Git | `git::https://example.com/vpc.git?ref=v1.2.0` (`ref` = branch, tag or SHA; default `HEAD`) |
| Mercurial | `hg::https://example.com/vpc.hg` |
| HTTP(S) archive | `https://example.com/vpc-module.zip` |
| S3 / GCS archive | `s3::https://s3.amazonaws.com/bucket/vpc.zip`, `gcs::https://www.googleapis.com/storage/v1/bucket/vpc.zip` |

- `//` picks a subfolder of a package; query string goes after it: `git::https://example.com/net.git//modules/vpc?ref=v1.2.0`
- `?depth=1` asks Git for a shallow clone (then `ref` must be a branch or tag, not a raw SHA)

- `terraform init` downloads and caches every module the config references
- Private registry access needs credentials: run `terraform login` (or put an API token in the CLI config file)

### Publishing to the public registry

- The module lives in a **public GitHub repo** (GitHub only for the public registry) named `terraform-<PROVIDER>-<NAME>` (e.g. `terraform-aws-vpc`; `<NAME>` may contain more hyphens)
- The GitHub repo description becomes the module's short description; follow the standard structure below so docs, submodules and examples are parsed
- Connect the repo to the registry once, then release by pushing a **semver tag**: `1.2.0` or `v1.2.0` (the `v` is optional). At least one valid tag must exist before the first publish; non-version tags are ignored
- Missing version? "Resync Module" in the registry UI re-reads every tag

### Publishing to a private registry (worked example)

- Same repo naming rule and tag-based versions, but the repo can be private and the module is shared only inside your HCP Terraform organisation
- Worked example: <https://github.com/sharifndlovu123/terraform-aws-demo-bucket> published as `app.terraform.io/devbridge-playground/demo-bucket/aws`
- Consumer example: [`examples/08-hcp-terraform/registry-consumer`](../examples/08-hcp-terraform/registry-consumer)
- Registry name and provider are read from the repo name: `terraform-aws-demo-bucket` -> name `demo-bucket`, provider `aws`

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

## Variable scope, outputs and versions (004: 5b, 5c, 5d)

```hcl
module "web" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.0"             # 5d: registry only; constrain it, then commit the lock file
  name    = var.app_name         # 5b: the module cannot see var.app_name, you pass it as an input
}

output "web_id" {
  value = module.web.id          # 5c: only the module's declared outputs are readable
}
```

- Each module has its own namespace: no access to the caller's `var.*`, `local.*` or resources, and the caller cannot reach inside the module, only `module.<NAME>.<OUTPUT>`
- A child module's input with no `default` is required by the caller
- Composition: wire one module's output into another's input (`subnet_id = module.net.subnet_id`); keep the tree shallow
- `version` takes the same constraint syntax as providers (`=`, `~>`, `>=`...). Changing it needs `terraform init` (or `init -upgrade` to move to a newer match)
- Rename a module call safely with a `moved` block (`from = module.old`, `to = module.new`); drop one with a `removed` block (see [05](05-state.md#refactoring-with-moved-and-removed-blocks-004-6d))

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

- `version` only works with registry sources (public or private); Git sources pin with `?ref=`, local paths use whatever is on disk
- Public registry = public GitHub repo only; private registry also accepts GitLab, Bitbucket and Azure DevOps
- A module cannot read the root's variables: everything goes in through arguments and comes back through outputs
