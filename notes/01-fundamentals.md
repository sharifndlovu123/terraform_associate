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

Also available: `experiments` (opt in to unfinished language features) and `provider_meta`.

## Providers

- A provider is a plugin that lets Terraform talk to one API: a cloud (AWS, Azure, GCP), a SaaS product (GitHub, Stripe) or something else entirely (Kubernetes, Postgres)
- Three tiers: **Official** (published by the vendor itself), **Verified** (partner-maintained), **Community** (anyone, no maintenance promise)
- `registry.terraform.io` is where providers and modules are searched and published; each page has docs and a ready-made usage snippet

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
- `terraform_data`: the built-in replacement, no extra provider needed; uses `triggers_replace`

## The fine line: Terraform vs config management

Rule of thumb for something like a database:

- Terraform builds it (instance, schema, users), and can do one-off bootstrap work
- A config management tool such as Ansible owns recurring jobs (backups, cleanup)

Examples: [`examples/04-provisioners`](../examples/04-provisioners), [`examples/05-modules-and-provider-alias`](../examples/05-modules-and-provider-alias)

## Gotchas

- The `template_file` data source is the legacy way to render cloud-init; `templatefile()` replaces it
- Don't hardcode secrets in `environment` blocks
