# Maintain Infrastructure

## Key points

- Upgrading provider and Terraform versions is maintenance too: pin what deploys (lock file), and run a nightly canary that floats to the newest allowed versions so breakage is found overnight and fixed in the morning. See [`examples/07-versions`](../examples/07-versions) and its `nightly-check.sh`
- Progressive versioning: staying on recent versions means small fixes often instead of one big painful upgrade later. Nightly `terraform plan` (or image builds) acts as the early warning

## Troubleshooting

| Error type | What it is | Fix |
|------------|------------|-----|
| Language | syntax or HCL mistake in the config | `terraform fmt`, `terraform validate`, `terraform version` (is the version what the config needs?) |
| State | state no longer matches reality | `terraform apply -refresh-only`, `terraform apply -replace=ADDR` |
| Core | bug in Terraform itself | turn on logging, open a GitHub issue |
| Provider | provider API changed or an edge case | turn on logging, open a GitHub issue |

Language and state errors are usually yours to fix; core and provider errors usually need the maintainers.

### Logging (004: 7c)

```bash
export TF_LOG=TRACE            # TRACE, DEBUG, INFO, WARN, ERROR (TRACE is the most detail)
export TF_LOG_CORE=ERROR       # core only
export TF_LOG_PROVIDER=TRACE   # providers only
export TF_LOG_PATH=./tf.log    # write to a file instead of the terminal
TF_LOG=JSON terraform plan     # JSON-formatted logs at TRACE level
```

- `TF_LOG_CORE` and `TF_LOG_PROVIDER` take the same values as `TF_LOG`
- Unset them (`unset TF_LOG`) when done; trace logs are huge and can contain sensitive values

### Crash log

- If Terraform itself crashes (a Go runtime panic) it writes `crash.log` with the session's debug logs, the panic message and the backtrace
- That file is for the developers: attach it to a GitHub issue, you do not need to read it

## Commands

### Import an existing resource (004: 7a, both ways)

```hcl
# 1. a placeholder block; the body can stay empty and is NOT filled in for you
resource "aws_instance" "example" {
  # ...instance configuration...
}
```

```bash
# 2. attach the real object to that address: terraform import <ADDRESS> <ID>
terraform import aws_instance.example i-abcd1234
```

- One resource per command
- Not every resource type is importable; the bottom of its provider doc page says so (and what the ID is)
- Afterwards write the config until `terraform plan` shows no changes

Config-driven import (1.5+), planned and reviewed like any other change:

```hcl
import {
  to = aws_instance.example
  id = "i-abcd1234"
}
```

```bash
terraform plan -generate-config-out=generated.tf   # drafts the resource block for you
terraform apply
```

- **Experimental**: `-generate-config-out` is still marked experimental in 1.12 docs and in 1.17.0 (plan prints "Config generation is experimental"). Review the file: it lists every attribute (often `= null`) and can contain conflicting arguments to delete by hand
- Only writes blocks for `import` targets that have no `resource` block yet; the output file must not already exist
- `id` must be known at plan time (literal, variable, local); `provider = aws.eu` picks an aliased provider
- Import blocks are idempotent: once the object is in state they do nothing, so delete them after the apply or keep them as a record
- One `import` block per object, unlike the CLI they go through `plan`, can be batched, and work in HCP Terraform VCS runs

**New (1.7)**: `for_each` on `import`, one block for many objects:

```hcl
locals {
  buckets = { staging = "bucket-stg", prod = "bucket-prod" }
}

import {
  for_each = local.buckets
  to       = aws_s3_bucket.this[each.key]
  id       = each.value
}

resource "aws_s3_bucket" "this" {
  for_each = local.buckets
  bucket   = each.value
}
```

**New (1.12)**: `identity = { ... }` instead of `id`, for providers whose resources publish a resource identity (the keys depend on the resource type). `id` and `identity` cannot be used together. Inspect identities with `terraform state identities -json`.

`import` CLI vs block:

| | `terraform import` | `import` block (1.5+) |
|---|---|---|
| Reviewed in a plan | no, writes state at once | yes |
| Many objects | one per command | many blocks, or `for_each` (1.7) |
| Can draft config | no | `-generate-config-out` (experimental) |
| HCP Terraform VCS runs | no (local CLI only) | yes |

Extra, not in 004: **New (1.14)** `terraform query` with `list` blocks in `*.tfquery.hcl` files searches a provider for existing objects and can generate `import` blocks plus config for them (needs provider support).

### Drift

```bash
terraform plan -refresh-only      # what changed outside Terraform
terraform apply -refresh-only     # accept it into state
```

Details in [05-state](05-state.md).

### Fix a damaged resource

```bash
terraform apply -replace='aws_instance.example[0]'
```

Details in [02-core-workflow](02-core-workflow.md).

## Gotchas

- `import` only writes state, never config (only `-generate-config-out` drafts config, and it is experimental)
- The `import` block's `to` must point at a `resource` block that exists, unless you are generating config for it
- Import blocks were root-module only when added in 1.5; 1.17.0 also accepted one inside a child module (tested). For the exam, put them in the root module
- After an import, a plan full of `~` changes just means your config does not match the real object yet
