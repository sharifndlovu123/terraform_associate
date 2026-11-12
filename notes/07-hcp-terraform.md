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

## Private registry

- Publish: Registry -> Publish -> Module, pick a connected VCS provider and a repo named `terraform-<PROVIDER>-<NAME>`; versions are semver tags
- Source address: `app.terraform.io/<ORG>/<NAME>/<PROVIDER>`; consumers run `terraform login` first
- Docs on the module page are generated from `README.md` and the `description` of each variable and output
- Walkthrough: [Modules note](04-modules.md#publishing-to-a-private-registry-worked-example)

## Gotchas

- Workspaces here are **not** the same as CLI workspaces: an HCP Terraform workspace is mandatory and holds everything for one set of infrastructure; a CLI workspace is optional and only gives you extra state files in one directory
- Execution mode decides where runs happen: remote (default), local (HCP Terraform only stores state) or via an agent
- When runs are remote, provider credentials must be set as workspace variables, not on your laptop

## `.terraformignore`

- In a CLI-driven remote run, an archive of your configuration directory is uploaded to HCP Terraform. List paths to leave out in a `.terraformignore` at the **root** of the config (gitignore-style syntax)
- Without one, the archive skips `.git/` and `.terraform/` (but keeps `.terraform/modules`)
- Only the root file is read; `.terraformignore` files in subdirectories are ignored

## Sentinel and policy as code

**Policy as code** = governance rules written as code and enforced automatically. **Sentinel** is HashiCorp's policy-as-code framework, embedded in the Terraform platform (and other HashiCorp products). It is its own language, not HCL.

| Sentinel feature | Meaning |
|------------------|---------|
| Embedded | checks sit in the data path and actively reject violating changes instead of just reporting them |
| Fine-grained, condition-based | decisions can depend on the values of other things |
| Multiple enforcement levels | advisory, soft-mandatory, hard-mandatory (below) |
| External information | policies can pull in outside data to decide |
| Multi-cloud | the same rules can govern several providers |

Benefits the course lists for policy as code: **sandboxing** (guardrails instead of manual checks), **codification** (the policy is exactly what is enforced), **version control** (history of changes), **testing** (syntax and behaviour validated with the CLI, see the example), **automation** (integrates with other systems to notify or remediate).

Course-era note: Sentinel was sold as part of the Team & Governance upgrade (see the plans below).

Policies people commonly write:

| Area | Examples |
|------|----------|
| AWS | restrict `aws_ami` owners, mandatory tags, allowed availability zones and instance types, no `0.0.0.0/0` in security groups, S3 private and KMS-encrypted, VPC DNS hostnames on |
| Azure | mandatory VM tags, allowed VM publishers, images and sizes, AKS limits, security-group CIDRs |
| GCP | mandatory labels, no `0.0.0.0/0` in firewalls, GKE limits, allowed machine types |
| VMware | Storage DRS, virtual disk size and type, CPU and memory limits, NFS 4.1 + Kerberos |
| Cloud-agnostic | allowed or prohibited providers, monthly cost limit, no providers in non-root modules, version constraints on all modules, resources only from the private registry, latest module versions |

Flow: SCM -> HCP Terraform -> `plan` -> **Sentinel policies** -> `apply` -> new infrastructure. You create a **policy set** in the organisation and attach it to workspaces.

Shape of a policy using the shared helper module (course slide, runnable version in the example):

```text
import "tfplan-functions" as plan

allowed_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
all_ec2_instances = plan.find_resources("aws_instance")
violating_ec2_instances = plan.filter_attribute_not_in_list(all_ec2_instances,
	"availability_zone", allowed_zones, true)

main = rule { length(violating_ec2_instances["messages"]) is 0 }
```

## Policy sets (Sentinel)

A **policy set** is a group of policies applied to chosen workspaces. Policies are checked after the plan, before apply. Runnable-style example: [`examples/08-hcp-terraform/sentinel`](../examples/08-hcp-terraform/sentinel).

```hcl
# sentinel.hcl: lists the policies in the set and how strictly each is enforced
policy "restrict-ec2" {
  source            = "./restrict-ec2.sentinel"
  enforcement_level = "hard-mandatory"
}
```

```text
# restrict-ec2.sentinel (shape only; full file in the example)
import "tfplan/v2" as tfplan
main = rule { all ec2_instances as _, rc { rc.change.after.instance_type in allowed_types } }
```

### Where the policies live

| Source | Notes |
|--------|-------|
| VCS repo (the usual way) | the policy set links to a repo and branch; policy changes arrive through pull requests |
| API or CLI upload | a pipeline packages and pushes the policies; the `tfe` provider can manage policy sets too |
| Entered in the UI | pasted by hand: fine for experiments, no history or review |

- A **separate** policy repo is the recommended pattern, not a rule: the platform or security team owns the guardrails, one policy set covers many workspaces, and policy changes get their own review and rollback
- Keeping policies beside the config is fine for a solo or learning project (the example folder does this for convenience)
- Written from memory of the docs, not tried here

### Enforcement levels

Set per policy in `sentinel.hcl` (or in the UI's **Enforcement mode** field). The values are case-sensitive strings:

```hcl
policy "naming" {
  source            = "./naming.sentinel"
  enforcement_level = "advisory"
}

policy "instance" {
  source            = "./instance.sentinel"
  enforcement_level = "soft-mandatory"
}

policy "no-public-s3" {
  source            = "./no-public-s3.sentinel"
  enforcement_level = "hard-mandatory"
}
```

| Value (Sentinel) | When `main` is false | Override? |
|------------------|----------------------|-----------|
| `advisory` | logged and shown in the UI, run continues | not needed |
| `soft-mandatory` | run stops before apply | yes, by a user with the **Manage Policy Overrides** permission (the organisation decides which teams) |
| `hard-mandatory` | run stops before apply | no, fix the config and re-run |

Other products use different names for the same idea:

| Policy type | Values |
|-------------|--------|
| Sentinel | `advisory`, `soft-mandatory`, `hard-mandatory` |
| OPA | `advisory`, `mandatory` (mandatory can be overridden by anyone with Manage Policy Overrides) |
| Terraform policy (newer language, per the docs, not tried here) | `Advisory`, `Mandatory overridable`, `Mandatory` |

- A policy set can also be set to "can be overridden in the event of mandatory failures": that lets admins or team owners override **any** failed policy in the set, even `hard-mandatory`, and it takes precedence over the per-policy level
- Pick the level by how bad a miss is: `advisory` for naming and tagging nudges, `soft-mandatory` when exceptions happen (approved larger instance), `hard-mandatory` for rules that must never break (public buckets)
- The local `sentinel test` only checks `main`; levels are applied by HCP Terraform, so they cannot be exercised locally

- Policies run in the order listed in `sentinel.hcl`; the rule named `main` decides pass or fail
- Connect it under **Settings > Policy Sets**: pick Sentinel, link the repo holding the policies, scope it to workspaces (or the whole organisation), choose a runtime version
- Sentinel imports give policies access to the plan (`tfplan/v2`), the configuration, state and run data (`tfrun`), and cost estimates (`tfcost`)
- Failed check: fix the config or the variable and queue a new run, or discard it
- Needs a plan that includes policy enforcement (see the plans table above)

| Where Sentinel runs | Cost |
|---------------------|------|
| Local `sentinel` CLI (`sentinel test`, `sentinel apply` against mock data) | free to download and use for writing and testing, no account (the download needed no login or licence key) |
| HCP Terraform policy sets (enforced on real runs) | paid plan with policy enforcement (Standard and up in the table above) |
| Terraform Enterprise | licensed |

The official CLI docs say nothing about licence terms, so check HashiCorp's terms before using the CLI commercially.

## Terms

| Term | Meaning |
|------|---------|
| Organization | a collection of workspaces |
| Workspace | belongs to an organization; one unique environment or stack (config, variables, state, runs) |
| Team | several users, assigned to workspaces |
| Run | one execution of Terraform in the run environment on an execution plan; can be started from the UI/VCS, the API or the CLI |

Other features the course lists: previous runs and state versions kept, secure variable injection, tags, **run triggers** (chain workspaces), a Terraform version chosen per workspace, state sharing across the organisation, comments on runs, notifications (webhooks, email, Slack), permissions at organisation and workspace level, Sentinel policy sets, MFA, SSO, cost estimation, integrations (ServiceNow, Splunk, Kubernetes) and custom run tasks.

## Workspaces and runs

**Local directory vs HCP Terraform workspace**: the same job, but the data lives in different places.

| Component | Local Terraform | HCP Terraform |
|-----------|-----------------|---------------|
| Configuration | on disk | in the linked VCS repo, or uploaded via API/CLI |
| Variable values | `.tfvars` files, CLI arguments, shell environment | in the workspace |
| State | on disk or in a remote backend | in the workspace |
| Credentials and secrets | shell environment or prompts | in the workspace, stored as sensitive variables |

**Run triggers**: connect a workspace to one or more **source workspaces** in the same organisation. A successful apply in a source workspace queues a run automatically in yours; each workspace can have up to 20 sources. Use it when a workspace relies on infrastructure or values produced by another (for example it reads them with data sources). Set it under **Settings > Run Triggers**; triggered runs are labelled "Queued automatically by ... from Run Trigger".


- Each workspace page has Overview, Runs, States, Variables and Settings tabs
- **Runs**: a history of runs; open one for the plan log, the apply log and confirmations, and leave a **comment** on any run. A plan can be a `destroy` run, and a plan can be **discarded**
- **States**: every state snapshot is kept, with a diff against the previous one and a **Download** button for the state file
- Plan view offers **Download Sentinel mocks** (test data for writing Sentinel policies)
- **Workflow options** per workspace: the Terraform version to use (any release), **share state globally** with other workspaces in the organisation, and the apply method (**auto apply** skips the manual confirmation, **manual apply** waits for a person)

## Run workflows (picked when you create a workspace)

| Workflow | How runs start |
|----------|----------------|
| Version control (UI/VCS, most common) | linked to one branch via webhooks: a pull request gets a speculative plan, a merge to that branch triggers a run |
| CLI-driven | you run `terraform plan` / `apply` locally and the run executes remotely |
| API-driven | a pipeline uploads a **configuration version** (a `.tar.gz` archive of the config) through the API and triggers a run |

VCS providers: GitHub (including OAuth, Enterprise and custom), GitLab (EE and CE), Bitbucket (Cloud, Server, Data Center) and Azure DevOps (Service, Server). The Terraform version, VCS connection and apply method are all set per workspace.

## Run environment

- Remote runs execute in a **single-use Linux x86_64 virtual machine or container** managed by HCP Terraform (its internals are not documented)
- These variables are injected into every run:

| Variable | Value |
|----------|-------|
| `TFC_RUN_ID` | unique run ID, e.g. `run-CKuwsxMGgMd3W7Ui` |
| `TFC_WORKSPACE_NAME` | workspace name |
| `TFC_WORKSPACE_SLUG` | `org/workspace`, e.g. `acme-corp/prod-load-balancers` |
| `TFC_CONFIGURATION_VERSION_GIT_BRANCH` | branch used, e.g. `main` |
| `TFC_CONFIGURATION_VERSION_GIT_COMMIT_SHA` | full commit hash |
| `TFC_CONFIGURATION_VERSION_GIT_TAG` | tag used, e.g. `1.1.0` |

```hcl
variable "TFC_RUN_ID" {}      # declare a variable with that name to read it in config
```

## Permissions

**Organization level** (manage things across the whole organisation)

- Manage policies (Sentinel), manage policy overrides (override soft-mandatory checks), manage workspaces, manage VCS settings
- **Organization owners** hold every permission, plus owner-only actions: publish private modules, invite users, manage team membership, view all secret teams, manage organisation permissions, settings and billing, manage agents, delete the organisation

**Workspace level**

| Fixed set | Includes |
|-----------|----------|
| Read | read runs, variables, state versions |
| Plan | read, plus queue plans |
| Write | plan, plus apply runs, lock/unlock workspace, download Sentinel mocks, read and write variables and state versions |
| Workspace admin | everything, plus workspace settings, set or remove team permissions, delete the workspace |

Custom workspace permissions let you grant individual abilities instead (read runs, queue plans, apply runs, lock/unlock, read/write variables, read state outputs, read/write state versions).

## API tokens

| Token | Scope and rules |
|-------|-----------------|
| Organization | whole organisation; one valid token at a time; only owners can create or revoke it; meant for creating and configuring workspaces and teams, not as an all-purpose key |
| Team | the workspaces that team can access, not tied to a person; one valid token per team; any team member can regenerate it, which immediately invalidates the old one |
| User | most flexible: inherits that user's permissions; can belong to a person or a machine user |

- `terraform login` obtains a **user** token. A **team** token has to be put into the CLI configuration file by hand
- Private registry access works with either a user or a team token (their permissions differ)
- A private registry is visible to every user in the organisation and offers module versioning, a searchable list and a configuration designer

## Cost estimation

- Shows the monthly cost of the resources in a run next to the plan: hourly cost, monthly cost and monthly delta per resource
- Only for certain resource types on AWS, Azure and GCP (for example `aws_instance`, `aws_db_instance`, `aws_ebs_volume`, `aws_lb`, `azurerm_virtual_machine`, `azurerm_managed_disk`, `google_compute_instance`, `google_sql_database_instance`)
- Pair it with a Sentinel policy to fail runs that would cost too much

## Agents

- Let HCP Terraform manage **isolated, private or on-premises** infrastructure (vSphere, Nutanix, OpenStack...)
- **Pull-based**: the agent polls HCP Terraform for work and runs it locally, so no inbound connectivity is needed
- Course-era requirements: x86_64 Linux (or the official agent Docker image), Terraform 0.12+, at least 4 GB free disk and 2 GB memory, outbound HTTPS (443) to `app.terraform.io`, `registry.terraform.io`, `releases.hashicorp.com` and `archivist.terraform.io`

## Terraform Enterprise

- The **self-hosted** distribution of the platform: a private instance with no resource limits plus enterprise features such as audit logging and SAML SSO
- You provide: a Linux instance, a TLS certificate and private key, a Terraform Enterprise **licence** from HashiCorp, and storage
- Operational modes (where data is kept): **External services** (PostgreSQL plus object storage such as S3, GCS, Azure Blob or Minio), **Mounted disk** (a separate disk, e.g. EBS or iSCSI), **Demo** (everything on the instance, not for production)
- Course-era sizing: at least 4 CPU cores, 8 GB memory, 10 GB root disk and 40 GB for the Docker data directory. Supported OS lists change by release, check the docs
- **Air-gapped** installs (no internet, common in government, military, finance and energy) are supported: you install or update from an **air gap bundle**, an archive of a release version

## Course-era plan names

The course (2021) describes: **Free** (up to 5 users, 1 concurrent run), **Teams & Governance** (from about $20 per user per month, 2 concurrent runs, adds team management, Sentinel policy management and cost estimation), **Business** (adds SSO, audit logging, self-hosted agents, configuration designer, ServiceNow integration, unlimited concurrent runs) and **Enterprise** (self-hosted, private). Current names and limits are in the plans table above.

