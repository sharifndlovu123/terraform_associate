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

# dynamic block: one nested block per element
dynamic "ingress" {
  for_each = var.rules            # iterator is named after the block: ingress.key / ingress.value
  # iterator = rule               # optional rename -> rule.value
  content {
    from_port = ingress.value.port
  }
}
for_each = var.on ? [1] : []      # trick: optional block (one or none)

# string directives
"Hi %{ if var.who != "" }${var.who}%{ else }there%{ endif }"
```

Runnable versions of all of these are in [`examples/`](examples/).

## Terraform console

Interactive prompt for trying expressions before putting them in config. Run it inside an initialised config directory.

```bash
terraform console                      # leave with `exit` or Ctrl+D
terraform console -var environment=prod
terraform console -plan                # evaluate against a fresh plan instead of current state
echo '1 + 2' | terraform console       # one-off, handy in scripts
```

- Never changes state; it only reads it
- Sees the config's `var.*`, `local.*` and any resources already in state (e.g. `terraform_data.app.output.tags.Service`)
- Before the first apply there is no state, so resource attributes print `(known after apply)`
- `type(x)` only exists in the console, useful for checking what type an expression really is

Samples (output shown after `->`):

```hcl
# strings
"Hello, ${upper("world")}!"                           # -> "Hello, WORLD!"
"Hello, %{ if 1 > 0 }yes%{ else }no%{ endif }"        # -> "Hello, yes"
format("%s-%03d", "web", 7)                           # -> "web-007"

# operators
5 + 3 * 2                                             # -> 11
10 % 3                                                # -> 1
1 == 1 && !false                                      # -> true

# collections
length(["a", "b", "c"])                               # -> 3
join("-", ["a", "b", "c"])                            # -> "a-b-c"
split(",", "x,y,z")                                   # -> tolist(["x", "y", "z"])
toset(["a", "b", "a"])                                # -> toset(["a", "b"])
merge({ a = 1 }, { b = 2 })                           # -> { a = 1, b = 2 }
lookup({ a = 1, b = 2 }, "c", 0)                      # -> 0 (key missing, falls back to the default)

# for expressions
[for n in ["a", "b"] : upper(n)]                      # -> ["A", "B"]
{for k, v in { a = 1, b = 2 } : k => v * 10}          # -> { a = 10, b = 20 }
[for n in ["a", "b", "c"] : upper(n) if n != "b"]     # -> ["A", "C"] (`if` filters)

# short for expression = Splat: [*] is shorthand for a plain "pull one attribute from every element" loop
[{ a = 1 }, { a = 2 }][*].a                           # -> [1, 2]
[for o in [{ a = 1 }, { a = 2 }] : o.a]               # -> [1, 2] (the long form of the line above)
[{ a = 1 }, { a = 2 }].*.a                            # -> [1, 2] (older `.*` spelling, same result)
[{ a = 1, b = [10, 20] }, { a = 2, b = [30] }][*].b[0]  # -> [10, 30] (keeps going after the splat)
var.docker_ports[*].external                          # -> tolist([80]) (works on a list of objects)
values({ x = { a = 1 }, y = { a = 2 } })[*].a         # -> [1, 2] (a map needs values() first)
null[*].a                                             # -> [] (null becomes an empty list)
"solo"[*]                                             # -> ["solo"] (a single value becomes a one-item list)

# type conversion and inspection
tostring(12)                                          # -> "12"
tonumber("42")                                        # -> 42
type(["a", 1])                                        # -> tuple([string, number])

# networking
cidrsubnet("10.0.0.0/16", 8, 1)                       # -> "10.0.1.0/24"
```

`cidrsubnet(prefix, newbits, netnum)` carves one smaller subnet out of a bigger network:

| Param | Meaning | In the sample |
|-------|---------|---------------|
| `prefix` | The parent network, as a CIDR string | `"10.0.0.0/16"` |
| `newbits` | How many bits to **add** to the prefix length, so the subnet mask grows (`/16` + 8 = `/24`) | `8` |
| `netnum` | Which subnet to pick from the ones that fit, counting from 0 | `1` (the second one) |

- Returns a CIDR string: the chosen subnet, `"10.0.1.0/24"` here
- `newbits` decides the subnet **size**, `netnum` decides which **slot** it is
- `netnum` runs from 0 to `2^newbits - 1`; with `newbits = 8` that is 0 to 255, and 256 errors
- More examples: `(…, 8, 0)` -> `"10.0.0.0/24"`, `(…, 8, 2)` -> `"10.0.2.0/24"`, `(…, 4, 1)` -> `"10.0.16.0/20"`
- Typical use: one VPC range, one `cidrsubnet` call per subnet using `count.index` as `netnum`

Try the variable/local ones from [`examples/01-variables-outputs-locals`](examples/01-variables-outputs-locals):

```hcl
var.environment                # -> "dev"
local.common_tags              # -> { Environment = "dev", Owner = "Platform Team", Service = "billing-api" }
var.docker_ports[0].external   # -> 80
```

Gotchas:

- Splat only extracts attributes from a list; to filter or transform, use the full `for` expression. On a map it fails with "does not have an attribute", so call `values()` first
- A splat returns a `list` but `[for ...]` returns a `tuple`, so `a[*].x == [for i in a : i.x]` is `false`; wrap the for in `tolist()` to compare (check with `type()`)
- Piping a multi-line heredoc in fails with "Invalid expression" (each line is parsed on its own); stick to single-line expressions when scripting
- `file()` and `path.module` resolve relative to the directory you launched the console from

## Versions

Read a version by **position**: first digit = **major**, second = **minor**, third = **patch** (`3.9.1`). Spec: <https://semver.org>

- patch bump `3.9.1 -> 3.9.2`: bug fix. minor bump `3.9.1 -> 3.10.0`: new feature, patch resets. major bump `3.9.1 -> 4.0.0`: breaking change, minor and patch reset
- Compare parts as whole numbers: `3.10.0` is newer than `3.9.1`
- `~> 3.6` means `>= 3.6.0, < 4.0.0` (major fixed); `~> 3.6.0` means `>= 3.6.0, < 3.7.0` (major and minor fixed)
- Operators: `=`, `!=`, `>`, `>=`, `<`, `<=`, `~>`; a comma means AND
- `.terraform.lock.hcl` records the exact provider versions chosen: commit it, `terraform init -upgrade` to move it
- Hands-on version in [`examples/07-versions`](examples/07-versions)

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
