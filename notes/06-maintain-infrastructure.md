# Maintain Infrastructure

## Key points

- Upgrading provider and Terraform versions is maintenance too: pin what deploys (lock file), and run a nightly canary that floats to the newest allowed versions so breakage is found overnight and fixed in the morning. See [`examples/07-versions`](../examples/07-versions) and its `nightly-check.sh`
- Progressive versioning: staying on recent versions means small fixes often instead of one big painful upgrade later. Nightly `terraform plan` (or image builds) acts as the early warning

## Commands

### Import an existing resource

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
terraform plan -generate-config-out=generated.tf   # drafts the resource block for you (experimental flag)
terraform apply
```

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

- `import` only writes state, never config
- After an import, a plan full of `~` changes just means your config does not match the real object yet
