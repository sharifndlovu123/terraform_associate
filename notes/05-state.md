# State Management

## Key points

- Default state file is `terraform.tfstate` in the working directory: JSON, version 4, one entry per resource instance mapped to its real object
- Top-level keys worth recognising: `version`, `terraform_version`, `serial` (bumps on every write), `lineage` (identity of this state), `outputs`, `resources`
- Contains values in plain text, including anything marked `sensitive`. Never commit it; use a remote backend
- Edit it with `terraform state ...` commands, not by hand

## Commands

```bash
terraform state list                       # every address in state
terraform state list module.network        # filter
terraform state show 'aws_instance.web[0]' # attributes of one instance
terraform state pull > backup.tfstate      # print current (remote) state to stdout
terraform state push backup.tfstate        # overwrite remote state from a local file
terraform state rm 'aws_instance.web[0]'   # forget it, real object is NOT destroyed
terraform state replace-provider registry.terraform.io/-/aws registry.terraform.io/hashicorp/aws
terraform state mv SOURCE DESTINATION      # see below
```

### `state mv`: rename or move without destroy/create

```bash
terraform state mv aws_instance.worker aws_instance.helper                    # rename
terraform state mv aws_instance.worker module.worker.aws_instance.worker      # resource -> module
terraform state mv module.app module.parent.module.app                        # module -> module
```

- Renaming a resource in config alone makes Terraform plan destroy old + create new. `state mv` updates the reference so nothing is rebuilt
- Rename the block in the `.tf` file too, then `terraform plan` should say no changes

The config-driven alternative (1.1+) is a `moved` block, which is reviewed in a plan and shared with everyone using the config:

```hcl
moved {
  from = aws_instance.worker
  to   = aws_instance.helper
}
```

### `state rm` then re-adopt

```bash
terraform state rm 'terraform_data.web[2]'   # Terraform stops managing it, the real thing stays
```

## Refreshing state

```bash
terraform plan  -refresh-only             # show drift (real world differs from state), change nothing
terraform apply -refresh-only             # accept the drift into state after you confirm
terraform apply -refresh-only -auto-approve
terraform refresh                         # deprecated alias for the line above
```

- Refresh never changes real infrastructure, only the state file
- `refresh` was deprecated because it wrote state with no review step; `-refresh-only` shows the plan first

Scenario: someone deletes a VM in the console on purpose.

| You run | Terraform does |
|---------|----------------|
| `terraform apply` | notices the VM is gone, proposes to create it again (config wins) |
| `terraform apply -refresh-only` | notices it is gone, proposes to drop it from state (reality wins) |

Other related flags: `-refresh=false` skips the refresh step (faster, riskier).

## Backends

A backend decides where state is stored and where operations run. Default (no `backend` block) is `local`.

| Kind | Stores state | Runs operations (plan/apply) | Examples |
|------|--------------|-------------------------------|----------|
| Standard | yes | no, your CLI does | `s3`, `azurerm`, `gcs`, `consul`, `pg`, `kubernetes`, `http`, `oss`, `cos`, `swift`, `etcdv3` |
| Enhanced | yes | yes | `local`, `remote` / the `cloud` block |

- Third-party backends are standard backends. They need no HCP Terraform account
- Locking depends on the backend: S3 (DynamoDB table, or native `use_lockfile` in newer versions), AzureRM, GCS, Consul, Postgres, Kubernetes and OSS (TableStore) lock; Artifactory does not; `http` locking is optional
- With a remote backend like S3, a local backup copy of the state still appears on your machine

```hcl
terraform {
  backend "s3" {
    bucket = "terraform-state000"
    key    = "statefile"
    region = "us-east-1"
  }
}

terraform {
  backend "local" {
    path = "relative/path/to/terraform.tfstate"
  }
}
```

### HCP Terraform as a backend

```hcl
terraform {                       # older style
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "company"
    workspaces {
      name = "my-app-prod"        # ONE workspace (or `prefix = "my-app-"` for several: apply asks which)
    }                             # name + prefix together is an Invalid workspaces configuration error
  }
}

terraform {                       # recommended: the cloud block (tags can select workspaces)
  cloud {
    organization = "company"
    workspaces {
      tags = ["app"]
    }
  }
}
```

- In remote runs HCP Terraform executes the commands, so provider credentials (e.g. `AWS_ACCESS_KEY_ID`, marked sensitive) must be set as **environment variables in the workspace**, not on your laptop

### Partial backend configuration

Keep dynamic or sensitive settings out of the code:

```hcl
terraform {
  backend "remote" {}
}
```

```hcl
# backend.hcl
workspaces { name = "workspace" }
hostname     = "app.terraform.io"
organization = "company"
```

```bash
terraform init -backend-config=backend.hcl
terraform init -backend-config="key=value"   # single settings also work
terraform init -migrate-state                # after changing backend: copy state over
terraform init -reconfigure                  # ignore the old backend, no copy
```

Runnable offline version: [`examples/09-backends-and-remote-state`](../examples/09-backends-and-remote-state).

## Reading another stack's state

```hcl
data "terraform_remote_state" "vpc" {
  backend = "remote"
  config = {
    organization = "hashicorp"
    workspaces = { name = "vpc-prod" }
  }
}

resource "aws_instance" "foo" {
  subnet_id = data.terraform_remote_state.vpc.outputs.subnet_id
}
```

For a local backend use `backend = "local"` with `config = { path = "../network/terraform.tfstate" }`.

- Only **root-level outputs** are exposed. To reach a nested module's value, add a pass-through root `output`
- Whoever uses it must be able to read the **whole** state, which can hold secrets
- Safer alternative: publish what others need to a separate place (SSM parameter, DNS, ...) and read it with ordinary **data sources**:

```hcl
data "aws_s3_bucket" "selected" { bucket = "bucket.test.com" }
data "aws_route53_zone" "test_zone" { name = "test.com." }

resource "aws_route53_record" "example" {
  zone_id = data.aws_route53_zone.test_zone.id
  name    = "bucket"
  type    = "A"
  alias {
    name    = data.aws_s3_bucket.selected.website_domain
    zone_id = data.aws_s3_bucket.selected.hosted_zone_id
  }
}
```

## Workspaces (CLI)

Several named states for one configuration (dev, prod, ...). Think of them like git branches for state: technically each is just another state file. (Before 0.9 they were called "environments".)

```bash
terraform workspace list          # * marks the current one; a fresh project only has `default`
terraform workspace new dev       # create and switch
terraform workspace select dev    # switch (`-or-create` makes it if missing)
terraform workspace show          # print the current name
terraform workspace delete dev    # cannot delete the one you are on, or `default`
```

```hcl
count = terraform.workspace == "default" ? 5 : 1   # use the workspace name in config
tags  = { Name = "web-${terraform.workspace}" }
```

- Local backend: states live in `terraform.tfstate.d/<name>/`; `default` stays in `terraform.tfstate`. Small teams sometimes commit them, but a remote backend is better with several collaborators
- Remote backend: the workspace states are stored in the backend itself
- Backends that support multiple workspaces: `local`, `remote`, `s3`, `gcs`, `azurerm`, `consul`, `kubernetes`, `pg`, `cos`, `manta`. One configuration still has one backend, you just get several states without changing credentials
- Not the same thing as HCP Terraform workspaces, which behave like completely separate working directories (see [07](07-hcp-terraform.md#workspaces-and-runs))

## Moving local state to HCP Terraform

```hcl
terraform {                      # before: nothing, default local state
}

terraform {                      # after
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "my-org"
    workspaces {
      name = "my-workspace"
    }
  }
}
```

Create the workspace in HCP Terraform, change the config, then `terraform init` (add `-migrate-state` to be explicit). Answer `yes` when asked to copy the existing state; `no` starts with an empty state. New configs should use the `cloud` block instead of `backend "remote"`.

## State locking

- Locking happens automatically on every operation that could write state, with no message unless acquiring the lock is slow
- `-lock=false` skips it on most commands (not recommended); `-lock-timeout=30s` waits and retries
- If a lock is left behind:

```bash
terraform force-unlock <LOCK_ID>          # the ID is printed when unlocking fails
terraform force-unlock -force <LOCK_ID>   # skip the confirmation prompt
```

- Only unlock your own stuck lock. Unlocking while someone else's run is active allows two writers and can corrupt state

## Protecting sensitive data

- State can hold secrets (long-lived cloud credentials, passwords) and is a target
- **Local backend**: plain-text JSON on disk; do not share it, never commit it
- **HCP Terraform**: state encrypted at rest and in transit, not written to your disk; Terraform Enterprise adds detailed audit logging
- **Third-party backends**: check they meet your security needs. For S3: turn on encryption and versioning, add a CloudTrail trail for data events

## Gotchas

- `state rm` does not delete anything real, it only makes Terraform forget
- `state push` can overwrite a teammate's newer state: `serial` and `lineage` checks guard it, `-force` bypasses them
- Rename without `state mv` / `moved` = destroy and recreate
- `.terraform.tfstate.lock.info` is the state lock, `.terraform.lock.hcl` is the provider dependency lock. Different things
