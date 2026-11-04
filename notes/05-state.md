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

## Gotchas

- `state rm` does not delete anything real, it only makes Terraform forget
- `state push` can overwrite a teammate's newer state: `serial` and `lineage` checks guard it, `-force` bypasses them
- Rename without `state mv` / `moved` = destroy and recreate
- `.terraform.tfstate.lock.info` is the state lock, `.terraform.lock.hcl` is the provider dependency lock. Different things
