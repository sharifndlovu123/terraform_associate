# HCP Terraform (Terraform Cloud)

Docs: <https://developer.hashicorp.com/terraform/cloud-docs>

## What it is

- A hosted service from HashiCorp (at `app.terraform.io`) that runs Terraform for a team: it keeps the state, runs plan/apply, and controls who may change what
- **Same product as "Terraform Cloud"**: renamed HCP Terraform in April 2024. Course material and the exam may still say either name
- **Terraform Enterprise** is the self-hosted version of the same thing, for organisations that need their own private install
- The idea in one line: it replaces your laptop as the place where Terraform runs and where state lives

## What it offers

| Feature | What you get |
|---------|--------------|
| **Workspaces** | one per collection of infrastructure; holds the config, variables, state, run history and permissions. **Projects** group workspaces |
| **Remote state** | stored centrally, previous versions kept, locked during a run; other workspaces can read outputs with `terraform_remote_state` |
| **Remote runs** | plan and apply happen on disposable VMs in HashiCorp's cloud, queued per workspace |
| **VCS integration** | link a repo (GitHub, GitLab, Bitbucket, Azure DevOps); merges to the linked branch start runs |
| **Private registry** | share modules inside your organisation (published from a VCS repo) |
| **Variables** | per workspace or shared through variable sets; cloud credentials can live here, marked sensitive |
| **Policy as code** | Sentinel or OPA checks that can block a run before apply |
| **Cost estimation** | estimated monthly cost of the planned changes |
| **Run tasks** | call external services (e.g. security scanners) during a run |
| **Access control** | teams, role-based permissions and SSO (SAML) |
| **Audit logging** | record of who did what |
| **Agents** | run Terraform inside your own network when the targets are not reachable from the internet |
| **Health assessments** | scheduled drift detection and continuous validation, see [below](#drift-detection-health-assessments) |

## What it can do (ways to start a run)

- **VCS-driven**: a commit merged to the linked branch starts a run; pull requests against it get a speculative plan (plan only, never applied)
- **CLI-driven**: run `terraform plan` / `apply` locally, but execution happens remotely
- **API-driven**: trigger runs from your own tooling or pipeline

Run stages, in order (each one is skipped if not enabled):

`plan` -> `OPA policy check` -> `cost estimation` -> `Sentinel policy check` -> `approval` -> `apply`

- Run tasks can hook in before plan, after plan, before apply and after apply
- A run that has changes waits for someone with permission to approve it, unless the workspace has auto-apply on
- A failed policy check can stop the run before apply (some policy results can be overridden)

## Drift detection (health assessments)

HCP Terraform's **health assessments** have two parts: drift detection and continuous validation.

**Drift detection**

- Drift = the real infrastructure no longer matches your configuration because someone changed it outside Terraform (e.g. editing a bucket in the cloud console)
- It runs on a schedule (the docs' example is every 24 hours after the last apply or assessment) and can also be started on demand by a workspace admin
- It only **reports**: HCP Terraform never changes your infrastructure as part of an assessment
- The docs call this *configuration* drift and say it is different from *state* drift, which drift detection does **not** detect
- Fixing drift: apply your configuration to overwrite the change, or edit the configuration to keep it
- Findings show as a **Health warning** on the Workspaces page, plus the **Drift** page; notifications follow the workspace notification settings

**Continuous validation**

- Re-checks your own assertions after deployment: `check` blocks, preconditions and postconditions
- Typical use: a `check` block that confirms a site still returns HTTP 200, or a certificate is not close to expiry
- Results show under **Health > Continuous validation**

**Requirements**

- Standard or Premium plan
- Execution mode must be **remote** or **agent** (not local)
- Terraform 0.15.4+ for drift detection, 1.3.0+ for continuous validation
- The workspace needs at least one successful apply, and its latest run must have succeeded (errored, canceled or discarded runs pause assessments)
- An assessment never interferes with a real run: if a run starts, the assessment is cancelled and rescheduled

Doing the same locally: `terraform plan -refresh-only` shows what changed outside Terraform without proposing config changes.

Docs: <https://developer.hashicorp.com/terraform/cloud-docs/workspaces/health>

## Code: the `cloud` block

```hcl
terraform {
  cloud {
    organization = "my-org"

    workspaces {
      name = "network-prod"
    }
  }
}
```

- `workspaces` takes a single `name`, or `tags` and/or a `project` to cover several workspaces
- Needs `terraform login` first (saves an API token in a credentials file), then `terraform init`
- It replaces the older `backend "remote"` setup
- Example that validates offline: [`examples/08-hcp-terraform`](../examples/08-hcp-terraform)

```bash
terraform login        # get and store a token for app.terraform.io
terraform init         # connects the config to the organisation and workspace
terraform plan         # runs remotely by default, output streams to your terminal
```

## Plans at a glance

Checked against the official docs on 2026-11-04. Plans and limits change, so confirm on the current plans page before relying on this.

| | Free | Essentials | Standard | Premium |
|---|------|------------|----------|---------|
| Managed resources | up to 500 | unlimited | unlimited | unlimited |
| Remote runs, VCS, private registry, SSO, run tasks | yes | yes | yes | yes |
| Teams and custom RBAC | no | yes | yes | yes |
| Policy enforcement and cost estimation | no | no | yes | yes |
| Health assessments (drift detection, continuous validation) | no | no | yes | yes |
| Audit logging | no | no | no | yes |
| Concurrent runs | 1 | 3 | 10 | 200 |

## Gotchas

- Workspaces here are **not** the same as CLI workspaces: an HCP Terraform workspace is mandatory and holds everything for one set of infrastructure; a CLI workspace is optional and only gives you extra state files in one directory
- Execution mode decides where runs happen: remote (default), local (HCP Terraform only stores state) or via an agent
- When runs are remote, provider credentials must be set as workspace variables, not on your laptop

## `.terraformignore`

- In a CLI-driven remote run, an archive of your configuration directory is uploaded to HCP Terraform. List paths to leave out in a `.terraformignore` at the **root** of the config (gitignore-style syntax)
- Without one, the archive skips `.git/` and `.terraform/` (but keeps `.terraform/modules`)
- Only the root file is read; `.terraformignore` files in subdirectories are ignored
