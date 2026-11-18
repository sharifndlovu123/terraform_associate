# Ecosystem Tools

Tools around Terraform. Marked **Newer** where the course slide is dated (checked 2026-11-12, confirm before relying on it).

## Consul

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
- **Newer**: Terraform 1.10+ added ephemeral values that are kept out of state, and newer Vault provider releases offer ephemeral resources for secrets. Check the provider docs for the current recommended way (not tried here)

## Atlantis

Open-source tool that automates Terraform pull requests: a bot runs `plan` and `apply` from PR comments and replies with the output, then the PR is merged. Built as an alternative to Terraform Cloud's VCS automation. Site: runatlantis.io.

- **Newer / correction**: the course says HashiCorp maintains it. Today Atlantis is a community project and a **CNCF Sandbox** project (accepted June 2024); its maintainers say it is not a HashiCorp product

## CDK for Terraform (CDKTF)

AWS CDK is an **imperative** IaC tool: write TypeScript, Python, Java, C# or Go and it synthesizes **CloudFormation** (AWS only). CDKTF is HashiCorp's separate project that generates **Terraform** configuration instead (JSON or HCL), so the CDK style works for any Terraform provider.

- **Newer / outdated**: HashiCorp deprecated and archived CDKTF on **2025-12-10**: no more fixes or provider compatibility updates. The recommended path is plain HCL (`cdktf synth --hcl` exports an existing project). Alternatives people mention: Pulumi, AWS CDK, OpenTofu, and a community fork (CDK Terrain). Treat CDKTF as a historical topic

## Gruntwork

Company building tools around Terraform:

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
- **Newer**: Terragrunt is on 1.x now and its CLI was reworked since the course (the `run-all` commands became `run --all`). Check `terragrunt --help` for your version

## Testing in Terraform

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
