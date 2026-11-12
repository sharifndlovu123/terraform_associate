# Sentinel policy with HCP Terraform

The Terraform config is an example only, **not applied** (needs AWS and an HCP Terraform workspace on a plan with policy support). The policy itself is tested locally with the free Sentinel CLI (v0.41.0) against hand-written mock plans, no account needed. It has not run in a real policy set yet.

Based on HashiCorp's tutorial: https://developer.hashicorp.com/terraform/tutorials/policy/sentinel-cloud-integration (paraphrased, see the README credit section).

| Folder | What it is |
|--------|------------|
| `config/` | EC2 instance whose type comes from `var.instance_type` |
| `policy/` | `restrict-ec2.sentinel` (Name tag + allowed types) and `sentinel.hcl` (enforcement level) |

## Test the policy locally (free)

```bash
cd policy
sentinel test            # runs test/restrict-ec2/*.hcl against the mock plans
sentinel test -verbose   # shows each rule's value
sentinel fmt -check restrict-ec2.sentinel
```

`test/restrict-ec2/` has three cases: `pass` (t2.micro with a Name tag), `fail-type` (t2.large) and `fail-tag` (no tags). Each `.hcl` points at a mock `tfplan/v2` file and states the expected value of `main`. Install the CLI from https://releases.hashicorp.com/sentinel/ (unzip, put on your PATH).

Test a single policy by name: `sentinel test restrict-ec2.sentinel`. The folder under `test/` must match the policy's file name (without `.sentinel`).

More: HashiCorp's testing tutorial https://developer.hashicorp.com/terraform/tutorials/policy/sentinel-testing (paraphrased). Its pattern is the same as here: copy a mock into a pass and a fail variant, one `.hcl` per case, expect `main = true` or `false`. A case that expects `false` and gets `false` reports PASS. Tips from it:

- Not sure your existing infrastructure complies? Run `sentinel apply <policy>` on the unedited mock data to find a failing case, then edit a copy into the passing mock (not tried here)
- Mocks are big: collapse the `planned_values` section in an editor to reach `resource_changes` faster
- In the tutorial the test case points at a mock one folder up (`source = "../../mock-tfplan-pass-v2.sentinel"`); here the mocks sit beside the case files, so the source is just the file name

## Using a shared function module

`restrict-azs.sentinel` (from the course slide) keeps instances in approved availability zones and uses HashiCorp's `tfplan-functions` helper module: `plan.find_resources("aws_instance")` and `plan.filter_attribute_not_in_list(...)`. The module is not copied into this repo, download it next to the policy:

```bash
cd policy
curl -O https://raw.githubusercontent.com/hashicorp/terraform-sentinel-policies/main/common-functions/tfplan-functions/tfplan-functions.sentinel
sentinel test            # now runs restrict-ec2 and restrict-azs
```

- In `sentinel.hcl` the helper is declared with a `module "tfplan-functions" { source = ... }` block (this is what HCP Terraform reads)
- The local CLI instead reads it from each test case: `import "module" "tfplan-functions" { source = "../../tfplan-functions.sentinel" }`, path relative to the test file (see `test/restrict-azs/*.hcl`)
- The `fail` case logs the reason: `aws_instance.demo has availability_zone with value eu-west-1a that is not in the allowed list: [...]`
- Without the download, only the `restrict-azs` tests error (`Import "tfplan-functions" is not available`); `restrict-ec2` is self-contained

## Mock files: what they are

A policy imports run data (`import "tfplan/v2" as tfplan`). In HCP Terraform that data comes from the real plan. Locally there is no plan, so `sentinel test` reads **mock files**: fake data with the same shape.

Each test case in `policy/test/restrict-ec2/` is two files:

| File | Role |
|------|------|
| `mock-pass.sentinel` | fake `tfplan/v2` data: `resource_changes` with one `aws_instance` (`instance_type`, `tags`) |
| `pass.hcl` | the test case: which mock feeds `tfplan/v2`, and the expected value of `main` |

```hcl
# pass.hcl
mock "tfplan/v2" {
  module { source = "mock-pass.sentinel" }
}
test {
  rules = { main = true }
}
```

The three mocks differ by one detail each (good instance, `t2.large`, no tags), so both the allow and block paths are covered.

### Real mocks from a run

The **Download Sentinel mocks** button on a run's plan (needs a workspace with policy support) gives one mock per import. A policy runs after the plan and before apply, so these describe what Terraform *intends*, not what happened:

| Mock | Tells you |
|------|-----------|
| `mock-tfplan-v2.sentinel` | proposed changes: each `resource_changes` entry has `actions` (`create`, `update`, `delete`, `no-op`) and `change.before` / `change.after` |
| `mock-tfstate-v2.sentinel` | the state the run started from |
| `mock-tfconfig-v2.sentinel` | the configuration: resources, providers, variables, module calls |
| `mock-tfrun.sentinel` | run metadata: workspace, VCS details, destroy run or not, cost estimate |

- State = the "before", `change.after` = the planned "after"; policies compare them
- Sensitive values are redacted or marked: check a downloaded mock before committing it
- Not tested here (needs a paid workspace). The mocks in this folder are the smallest slice of `tfplan/v2` that `restrict-ec2.sentinel` reads, so a real plan could still differ in shape

## Steps (from the tutorial)

1. Put `config/` in a repo and create a **VCS-driven workspace** for it
2. Workspace variables: `instance_type`, plus `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` as sensitive environment variables
3. Put `policy/` in its own repo, then in the organisation go to **Settings > Policy Sets > Connect a new policy set**: framework Sentinel, scope it to the workspace, pick a runtime version
4. Queue a run with `instance_type = "t2.large"`: the policy check fails and the run cannot be applied
5. Set it back to `t2.micro`: the check passes. Discard the run if you do not want to apply
6. Clean up: delete the policy set (and the workspace)

## Enforcement levels

`enforcement_level` in `sentinel.hcl` takes one of:

| Value | Failing policy |
|-------|----------------|
| `"advisory"` | logged only, the run continues |
| `"soft-mandatory"` | blocks the run, but a user with Manage Policy Overrides can override |
| `"hard-mandatory"` | blocks the run, no override (unless the policy set itself allows overrides) |

OPA policies use `advisory` / `mandatory`. Details and the comparison table: [07-hcp-terraform](../../../notes/07-hcp-terraform.md#enforcement-levels).

Policies run after the plan (and after cost estimation), see [07-hcp-terraform](../../../notes/07-hcp-terraform.md).
