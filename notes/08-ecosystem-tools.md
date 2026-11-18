# Ecosystem Tools

Tools around Terraform. Marked **Newer** where the course slide is dated (re-checked 2026-11-18 against official docs, project repos and sites; confirm before relying on it).

004 scope: only the **Vault / secrets** part is tested (**4h**, sensitive data and secrets management). Consul, Atlantis, CDKTF, Gruntwork (Terragrunt, Terratest), Kitchen-Terraform and the testing pyramid are **Extra, not in 004**: kept for background.

## Consul

**Extra, not in 004.**

Service networking platform: service discovery (central registry, services talk directly, no load balancer as single point of failure), service mesh (traffic between services, "middleware" layer) and application configuration. Worth it with hundreds or thousands of services.

With Terraform: as a **remote backend** (state in Consul's key/value store, with locking) and as a **provider**. Runnable config: [`examples/11-ecosystem-tools/consul`](../examples/11-ecosystem-tools/consul).

```hcl
terraform {
  backend "consul" {
    address = "127.0.0.1:8500"
    scheme  = "http"
    path    = "terraform/state/demo"
  }
}
```

## Vault and Terraform

004: 4h.

Vault gives one interface to many secret stores (AWS, Consul KV, Google Cloud KMS, Azure service principals), with tight access control: **just-in-time** (short windows) and **just enough privilege** (least permission), plus a tamper-evident audit log. Runs as a cluster on VMs and can be backed up with snapshots.

Why with Terraform: AWS keys are long-lived and sit on a laptop. Vault can **inject short-lived credentials at apply time** through a data source:

```hcl
provider "vault" {}   # VAULT_ADDR, VAULT_TOKEN

data "vault_aws_access_credentials" "creds" {
  backend = "aws"
  role    = "deploy"
}

provider "aws" {
  region     = "us-east-1"
  access_key = data.vault_aws_access_credentials.creds.access_key
  secret_key = data.vault_aws_access_credentials.creds.secret_key
  token      = data.vault_aws_access_credentials.creds.security_token
}
```

Full file: [`examples/11-ecosystem-tools/vault-credentials`](../examples/11-ecosystem-tools/vault-credentials).

- Data source results are written to **state**, so those credentials end up in the state file (short-lived, but still protect the state)
- **New (1.10)**: ephemeral resources (`ephemeral` block) plus ephemeral input variables and outputs: values never written to plan or state. **New (1.11)**: write-only arguments (`*_wo`) on managed resources accept ephemeral values without storing them. Both exist in Terraform 1.12, the version 004 tests
- The Vault provider (now **5.x**, 5.13.0 latest on 2026-11-18; the course era was 3.x/4.x) has ephemeral versions of many secret sources, e.g. `vault_aws_access_credentials`, `vault_kv_secret_v2`, `vault_database_secret`. Same idea as above, kept out of state (from the provider docs, not tried here):

```hcl
ephemeral "vault_aws_access_credentials" "creds" {
  mount = "aws"        # ephemeral version says mount, the data source says backend
  role  = "deploy"
  type  = "sts"        # sts also returns security_token
}

provider "aws" {
  access_key = ephemeral.vault_aws_access_credentials.creds.access_key
  secret_key = ephemeral.vault_aws_access_credentials.creds.secret_key
  token      = ephemeral.vault_aws_access_credentials.creds.security_token
}
```

- In HCP Terraform, **dynamic provider credentials** (OIDC, incl. Vault-backed) avoid stored keys altogether, see [notes/07](07-hcp-terraform.md#organise-and-govern-004-8b-8c)

## Atlantis

**Extra, not in 004.** Open-source tool that automates Terraform pull requests: a bot runs `plan` and `apply` from PR comments and replies with the output, then the PR is merged. Built as an alternative to Terraform Cloud's VCS automation. Site: runatlantis.io.

- **Newer / correction**: the course says HashiCorp maintains it. Today Atlantis is a community project and a **CNCF Sandbox** project (accepted June 2024); its maintainers say it is not a HashiCorp product. Re-checked 2026-11-18: still CNCF Sandbox (accepted 2024-06-18), repo active

## CDK for Terraform (CDKTF)

**Extra, not in 004.** AWS CDK is an **imperative** IaC tool: write TypeScript, Python, Java, C# or Go and it synthesizes **CloudFormation** (AWS only). CDKTF is HashiCorp's separate project that generates **Terraform** configuration instead (JSON or HCL), so the CDK style works for any Terraform provider.

- **Newer / outdated**: HashiCorp deprecated and archived CDKTF on **2025-12-10**: no more fixes or provider compatibility updates. HashiCorp's advice (README, re-checked 2026-11-18, repo archived/read-only): move to plain Terraform + HCL (`cdktf synth --hcl` writes `.tf` files, then normal `init`/`plan`/`apply`, expect some cleanup), or to AWS CDK if the stack is already tied to it. Code is MPL, so community forks are welcome (e.g. CDK Terrain, not checked). Treat CDKTF as a historical topic

## Gruntwork

**Extra, not in 004.** Company building tools around Terraform:

| Product | What it is |
|---------|------------|
| Infrastructure as Code Library | large library of reusable, tested code for AWS, GCP, Azure |
| **Terragrunt** | thin Terraform wrapper: keep config DRY, work with many modules, manage remote state |
| **Terratest** | Go testing framework for infrastructure |
| Landing Zone for AWS | baselines for multi-account AWS security |
| Pipelines | security-first CI/CD for infrastructure |
| Reference Architecture | opinionated way to assemble the library |

### Terragrunt

DRY = don't repeat yourself. A `terragrunt.hcl` per folder pulls a module in, generates boilerplate and feeds inputs, instead of copying provider and backend blocks into every module.

```hcl
terraform {
  source = "tfr:///terraform-aws-modules/vpc/aws?version=3.5.0"   # registry shorthand, extra / required
}

generate "provider" {              # write provider.tf before each run (values plain Terraform cannot compute)
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF2
provider "aws" {
  region = "us-east-1"
}
EOF2
}

inputs = {                         # the module's variables
  name = "my-vpc"
  cidr = "10.0.0.0/16"
}
```

File: [`examples/11-ecosystem-tools/terragrunt`](../examples/11-ecosystem-tools/terragrunt) (not run: Terragrunt was not installed here).

- It also keeps modules small, which helps when writing unit tests for infrastructure
- **Newer**: Terragrunt is on 1.x now (1.2.2 on 2026-11-11) and its CLI was reworked since the course: the `run-all` commands became `run --all` (e.g. `terragrunt run --all plan`; `apply`/`destroy` add `-auto-approve` for you, `--filter` narrows units). Docs moved to docs.terragrunt.com. Re-checked 2026-11-18; check `terragrunt --help` for your version

## Testing in Terraform

**Extra, not in 004** (the pyramid and third-party tools). Whether 004 covers `terraform test` is tracked separately in the sweep list (not checked here).

- **Newer** (re-checked 2026-11-18 on GitHub): **Kitchen-Terraform** is archived (last release 7.0.2, 2023), treat as dead; **terraform-compliance** still released (1.17.2, 2026-11-12); **InSpec** still active (Chef/Progress, 5.24.x)

| Rung | Tests | Tools |
|------|-------|-------|
| Static analysis (no deploy) | the code as written | `terraform fmt -check`, `terraform validate`, `terraform plan`, TFLint, terraform-compliance, Sentinel |
| Unit | one module (keep modules small) | Terratest, Kitchen-Terraform, InSpec, **`terraform test`** |
| Integration | several modules together | Terratest |
| End to end | the whole architecture in a persistent environment | e.g. Gruntwork Reference Architecture |

Speed and trade-offs (Gruntwork talk, QCon 2019):

| Technique | Strengths | Weaknesses |
|-----------|-----------|------------|
| Static analysis | fast, stable, no real resources, easy | catches few errors, little confidence alone |
| Unit | 1 to 10 min, mostly stable (with retries), high confidence per unit | deploys real resources, non-trivial code |
| Integration | confidence in modules working together | deploys real resources, 10 to 30 min |
| End to end | confidence in the whole architecture | real resources, 60 to 240+ min, can be brittle |

### Terratest

Temporarily deploys the infrastructure, checks the result, then tears it down. Tests are written in **Go** (little Go knowledge needed):

```go
func validateHelloWorldApp(t *testing.T, terraformOptions *terraform.Options) {
	url := terraform.Output(t, terraformOptions, "url")     // read an output variable
	expectedStatus := 200
	expectedBody := "Hello, World!"
	maxRetries := 10
	timeBetweenRetries := 3 * time.Second
	http_helper.HttpGetWithRetry(t, url, nil, expectedStatus, expectedBody, maxRetries, timeBetweenRetries)
}
```

(Fragment only: a real test also sets up `terraform.Options` and runs `terraform.InitAndApply`, not run here.)

### `terraform test` (newer, built in)

Since Terraform 1.6 you can write tests in HCL instead of Go, with `run` blocks and `assert`s. Runs offline in [`examples/12-testing`](../examples/12-testing):

```bash
terraform test
terraform test -verbose
```

```hcl
run "default_names" {
  command = plan                     # plan only; `apply` creates and later destroys real resources
  assert {
    condition     = output.names[0] == "web-dev-0"
    error_message = "first server should be named web-dev-0"
  }
}
```

- A negative test uses `expect_failures = [var.env]` and passes only if that validation fails
- Values that are only known after apply (for example a `terraform_data` output) cannot be asserted in a `plan` run: use `command = apply`, or build the value from a local
