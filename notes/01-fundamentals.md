# Terraform Fundamentals

## Config files

- Files end in `.tf`; the JSON flavour ends in `.tf.json` and suits machine-generated config
- Three building pieces: **blocks** (`type "label" "label" { ... }`), **arguments** (`name = value`) and **expressions** (anything that produces a value)
- HCL is the underlying toolkit; the Terraform language is the dialect you actually write

## `terraform` settings block

```hcl
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.7.0"
    }
  }
}
```

Version numbers read major.minor.patch (first, second, third digit). Constraint operators and the lock file are in [`examples/07-versions`](../examples/07-versions).

Also available: `experiments` (opt in to unfinished language features) and `provider_meta`.

## Dependency lock file (004: 2a, 3b)

- `.terraform.lock.hcl`, written by `terraform init`; commit it so every run picks the same provider builds
- Per provider it records the chosen `version`, the `constraints` from config and `hashes` (`h1:`/`zh:` checksums of the package)
- Without `-upgrade`, `init` reuses the locked version even if a newer one matches the constraint
- Tracks **providers only**, not modules (modules re-resolve from their `version` each `init`)
- Teams on mixed OSes: `terraform providers lock -platform=linux_amd64 -platform=darwin_arm64` adds checksums for each platform

```hcl
provider "registry.terraform.io/hashicorp/aws" {
  version     = "6.73.0"
  constraints = "~> 6.0"
  hashes      = ["h1:...", "zh:..."]
}
```

## Providers (004: 2a, 2b, 2c)

- A provider is a plugin that lets Terraform talk to one API: a cloud (AWS, Azure, GCP), a SaaS product (GitHub, Stripe) or something else entirely (Kubernetes, Postgres)
- Three tiers: **Official** (published by the vendor itself), **Verified** (partner-maintained), **Community** (anyone, no maintenance promise)
- `registry.terraform.io` is where providers and modules are searched and published; each page has docs and a ready-made usage snippet
- Source address `[hostname/]namespace/type`: `hashicorp/aws` is short for `registry.terraform.io/hashicorp/aws`. Always set `source` in `required_providers`; the local name (`aws`) is what the rest of the config uses
- Each provider is a separate executable that `init` downloads into `.terraform/providers/`; Core starts it and talks to it over RPC. `TF_PLUGIN_CACHE_DIR` shares one download across working directories
- One config can use many providers at once (e.g. `aws` + `azurerm` + `random`): list each in `required_providers`, configure each in its own `provider` block
- **New (1.8)**: provider-defined functions, called as `provider::<local name>::<function>(...)`; the provider must be in `required_providers`. Example: `provider::terraform::encode_expr({ a = 1 })` (built-in provider, source `terraform.io/builtin/terraform`, checked on 1.17.0)

### Provider alias (multiple configs of one provider)

```hcl
provider "aws" {
  alias  = "eu"
  region = "eu-west-1"
}

resource "aws_instance" "app" {
  provider = aws.eu
}
```

For modules, see [modules](04-modules.md).

## Provisioners

Extra, not in 004: provisioners left the objectives at 003 and are not back in 004. Still useful to know they are a last resort.

Last resort; prefer cloud-init, user_data or baked images (Packer / EC2 Image Builder).

| Provisioner | Runs | Notes |
|-------------|------|-------|
| `local-exec` | on the machine running Terraform, after the resource is created | args: `command` (required), `working_dir`, `interpreter`, `environment` |
| `remote-exec` | on the target resource | one mode only: `inline`, `script`, `scripts` |
| `file` | copies files/dirs to the target | `source` or `content`, plus `destination` |

- `remote-exec` and `file` need a `connection` block (`type = "ssh"` or `"winrm"`, SSH supports bastion hosts)
- Inside provisioners use `self.<attr>` to reference the resource
- `local-exec` is a common hook for kicking off config management (Ansible, Chef, Puppet)

### null_resource / terraform_data

- `null_resource`: a resource with no real infrastructure behind it, used to hang provisioners on; its `triggers` map re-runs them when a value changes
- **New (1.4)** `terraform_data`: the built-in replacement, no extra provider needed; uses `triggers_replace` (re-create on change) and `input` / `output` (store a value in state)

## The fine line: Terraform vs config management

Rule of thumb for something like a database:

- Terraform builds it (instance, schema, users), and can do one-off bootstrap work
- A config management tool such as Ansible owns recurring jobs (backups, cleanup)

Examples: [`examples/04-provisioners`](../examples/04-provisioners), [`examples/05-modules-and-provider-alias`](../examples/05-modules-and-provider-alias)

## Gotchas

- The `template_file` data source is the legacy way to render cloud-init; `templatefile()` replaces it
- Don't hardcode secrets in `environment` blocks
- The lock file pins providers, not modules, and not Terraform itself (`required_version` does that)
- `init -upgrade` is the only normal way to move past a locked provider version
