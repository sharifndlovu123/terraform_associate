# Core Workflow

Write -> `init` -> `validate` / `fmt` -> `plan` -> `apply` -> `destroy`.

## Workflows by team size

Always **Write -> Plan -> Apply**; what surrounds it grows with the team.

| | Individual | Team (open source CLI) | Team on HCP Terraform |
|---|---|---|---|
| Write | local editor, code in a VCS, repeat `validate`/`plan` | feature branch per person (avoids conflicts, merge resolves them) | same, but variables and credentials live in the workspace |
| Plan | commit locally, then plan | plan generated on the pull request by CI and shown in the PR | speculative plan on the PR, reviewable in the VCS and in HCP Terraform |
| Apply | run `apply`, review, approve, then push commits | approve and merge, a build server runs `terraform apply` | merge triggers a remote run, a team member confirms and applies |

Cost of the middle column: you build and run the CI/CD pipeline, choose and secure remote state, handle secrets on the build server, and get coarse access control (cannot say who may `apply` vs `destroy`). HCP Terraform takes most of that over, plus run history for audits.

## `terraform init`

Run first in any new directory, and again after changing providers, modules or the backend.

```bash
terraform init                    # download providers + modules, create .terraform/ and .terraform.lock.hcl
terraform init -upgrade           # move providers to the newest version the constraints allow
terraform init -plugin-dir=PATH   # only look for providers in this local directory
terraform init -get-plugins=false # old flag to skip provider install; removed from current Terraform, still shows up in courses
terraform init -lockfile=readonly # fail instead of touching .terraform.lock.hcl
```

| File / dir | What it is |
|------------|------------|
| `.terraform/` | downloaded providers and modules (do not commit) |
| `.terraform.lock.hcl` | dependency lock file: exact provider versions (commit it) |
| `terraform.tfstate` | the state file |
| `.terraform.tfstate.lock.info` | transient state lock while a run is in progress (not the dependency lock) |

## `terraform get`

```bash
terraform get            # download/refresh modules only
terraform get -update    # re-fetch modules already downloaded
```

- Lighter than `init`: no providers, no backend
- Handy while developing a local module; otherwise just use `init`

## `terraform fmt`

```bash
terraform fmt              # rewrite .tf files in this directory
terraform fmt -recursive   # include subdirectories
terraform fmt -check       # no rewrite, exit code 3 if anything needs formatting (CI)
terraform fmt -diff        # print what changed
```

- Fixes style only (two-space indent, aligned `=`). It cannot repair broken syntax: `provider "aws"` with the `{` on the next line is an `Invalid block definition` error

## `terraform validate`

```bash
terraform validate         # syntax and internal consistency, no cloud calls
terraform validate -json   # machine-readable, good for CI
```

```text
Error: Missing required argument
  The argument "instance_type" is required, but no definition was found.
```

- Needs `init` first (it reads provider schemas), but needs no credentials or state
- `plan` and `apply` run it for you

## `terraform plan`

```bash
terraform plan                          # preview only, changes nothing
terraform plan -out=tfplan              # save the plan as a binary file
terraform plan -var 'env=prod' -var-file=prod.tfvars
terraform plan -target=aws_instance.web # one resource (and its dependencies) only
terraform plan -replace='aws_instance.web[0]'
terraform plan -refresh-only            # compare state to reality, ignore config changes
terraform plan -destroy                 # preview a destroy
terraform plan -detailed-exitcode       # exit 0 no changes, 1 error, 2 changes (CI)
terraform show tfplan                   # read a saved plan
```

A plan: refreshes state from the real objects, diffs config against state, proposes actions. It never carries them out.

## `terraform apply`

```bash
terraform apply                  # plan, show it, wait for you to type yes
terraform apply -auto-approve    # no prompt
terraform apply tfplan           # saved plan: runs exactly that plan, no prompt
```

| Mode | Command | Prompts? |
|------|---------|----------|
| Automatic plan | `terraform apply` | yes (`yes` only) |
| Saved plan | `terraform apply tfplan` | no, behaves as auto-approve |

- A saved plan is stale if state or config changed since it was made; Terraform refuses it
- A saved plan can contain secrets, treat the file as sensitive

## `terraform destroy`

```bash
terraform destroy                          # everything in state
terraform destroy -target=aws_instance.web
terraform apply -destroy                   # same thing
```

## Replacing a resource

```bash
terraform apply -replace='aws_instance.example[0]'   # preferred
terraform taint aws_instance.my_web_app              # deprecated (0.15.2): marks it, replaced on next apply
terraform untaint aws_instance.my_web_app
```

- `-replace` shows the replacement in the plan before you approve; `taint` changes state first and shows nothing
- Use it when a resource exists but is broken (degraded, hand-edited) and you want a fresh one

## Resource addresses

`[module path][resource spec]`, used by `-target`, `-replace`, `state`, `import`:

```text
aws_instance.web                      # resource_type.name
aws_instance.web[3]                   # 4th instance (count, zero-based)
aws_instance.web["blue"]              # for_each key (quote the address in a shell)
module.network.aws_subnet.public      # resource inside a module
module.app[0].module.db.aws_db_instance.main   # nested modules, indexed module
data.aws_vpc.main                     # a data source
```

## Gotchas

- `fmt` formats, `validate` checks; neither talks to the cloud
- `-target` is for emergencies; it skips parts of the graph
- `apply tfplan` does not ask for approval
- `taint` is deprecated, reach for `-replace`
- Quote addresses with `[ ]` or `" "` so the shell leaves them alone: `-replace='aws_instance.web["blue"]'`
