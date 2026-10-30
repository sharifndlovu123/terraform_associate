# Terraform Cheat Sheet

## CLI

| Command | What it does |
|---------|--------------|
| `terraform init` | Download providers/modules, configure backend |
| `terraform fmt` | Format files to canonical style |
| `terraform validate` | Check syntax and internal consistency |
| `terraform plan` | Show what would change |
| `terraform apply` | Make the changes |
| `terraform destroy` | Tear everything down |
| `terraform show` | Inspect state or a saved plan |
| `terraform output [name]` | Print output values (`-json`, `-raw` for a single string) |
| `terraform apply -var 'k=v'` / `-var-file=f.tfvars` | Set variables from the CLI |
| `terraform state list` | List resources in state |

## HCL patterns

```hcl
# variable with validation
variable "env" {
  type = string
  validation {
    condition     = contains(["dev", "prod"], var.env)
    error_message = "env must be dev or prod."
  }
}

# provider alias
provider "aws" {
  alias  = "eu"
  region = "eu-west-1"
}
resource "aws_instance" "x" { provider = aws.eu }
module "m" {
  source    = "./m"
  providers = { aws = aws.eu }
}

# count / for_each
count    = var.on ? 1 : 0              # count.index
for_each = toset(["x", "y"])           # each.key / each.value
depends_on = [aws_iam_role_policy.p]

# lifecycle
lifecycle {
  create_before_destroy = true
  prevent_destroy       = true
  ignore_changes        = [tags]
}

# string directives
"Hi %{ if var.who != "" }${var.who}%{ else }there%{ endif }"
```

Runnable versions of all of these are in [`examples/`](examples/).

## Variable precedence (later wins)

env `TF_VAR_*` < `terraform.tfvars` < `terraform.tfvars.json` < `*.auto.tfvars[.json]` < `-var` / `-var-file`

## Plan symbols

`+` create, `-` destroy, `~` update in place, `-/+` destroy and recreate

## Gotchas

- `sensitive = true` hides values in the CLI only; they stay in the state file in plain text
- `for_each` needs a map or set: wrap lists in `toset()`
- `count` / `for_each` values must be known at plan time
- Ternary branches must have the same type
- `dev.tfvars` is not autoloaded; `dev.auto.tfvars` is
- Provisioners are a last resort: prefer cloud-init, user_data or baked images
- `remote-exec` and `file` need a `connection` block; use only one of `inline` / `script` / `scripts`
- Provisioners can use `self`; destroy-time ones (`when = destroy`) can only use `self`
- Provider tiers: Official, Verified, Community
