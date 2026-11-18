# Configuration

## Input variables

Arguments you can set: `type`, `default` (having one makes the variable optional), `description`, `validation`, `sensitive`, `nullable`, and **New (1.10)** `ephemeral` (see [sensitive data](#sensitive-data-004-4h)).
Declared in the root module or in child modules. 004: 4c.

### How values are loaded

| Source | Autoloaded? |
|--------|-------------|
| `terraform.tfvars` / `terraform.tfvars.json` | yes |
| `*.auto.tfvars` / `*.auto.tfvars.json` | yes |
| `dev.tfvars` etc. | no, pass with `-var-file=dev.tfvars` |
| `-var 'ec2_type=t2.medium'` | CLI |
| `TF_VAR_<name>` | env var |

### Precedence (later overrides earlier)

1. Environment variables
2. `terraform.tfvars`
3. `terraform.tfvars.json`
4. `*.auto.tfvars` / `*.auto.tfvars.json`
5. `-var` and `-var-file`

## Outputs

- `output "name" { value, description, sensitive, depends_on, precondition }`, plus **New (1.10)** `ephemeral = true` (child modules only, a root output cannot be ephemeral)
- `sensitive = true` only masks CLI output; the value is **still stored in state**
- Another stack can read them through the `terraform_remote_state` data source

## Locals

`locals { }` gives an expression a name so it can be reused within the module. You can have several blocks and locals can build on each other. Refer to them as `local.<name>`.

## Data sources

`data "aws_ami" "web" { ... }` looks up something that already exists elsewhere. Narrow results with `filter`; read them via `data.<type>.<name>.<attr>`.

## Named values

| Thing | Reference |
|-------|-----------|
| Resource | `<type>.<name>` |
| Input variable | `var.<name>` |
| Local | `local.<name>` |
| Child module output | `module.<name>.<output>` |
| Data source | `data.<type>.<name>` |
| Paths | `path.module`, `path.root`, `path.cwd` |
| Workspace | `terraform.workspace` |
| Block-local | `count.index`, `each.key`, `each.value`, `self.<attr>` |

Named values are not objects, so no `[]` access on them.

## Meta-arguments

- **`depends_on`**: declare an ordering Terraform can't work out from references (see [dependencies](#dependencies-004-4f))
- **`count`**: stamp out N copies; `count.index` is zero-based; needs a whole number known at plan time
- **`for_each`**: one instance per map entry or set element (`each.key`, `each.value`); lists must go through `toset()`
- **`provider`**: pick an aliased provider (`provider = aws.eu`)
- **`lifecycle`**: `create_before_destroy`, `prevent_destroy`, `ignore_changes`, `replace_triggered_by` (1.2), `precondition` / `postcondition` (1.2)

## Dependencies (004: 4f)

- **Implicit**: referencing another object's attribute (`subnet_id = aws_subnet.a.id`) adds a graph edge; Terraform creates `aws_subnet.a` first. Preferred, because it is visible in the code
- **Explicit**: `depends_on = [aws_iam_role_policy.x]` for a hidden dependency (e.g. an app instance needs an IAM policy it never references). Takes a list of whole resources/modules, not attributes; static references only
- Works on resources, data sources, modules (0.13+) and outputs
- Overusing `depends_on` makes plans more conservative: values downstream can stay "known after apply", data sources get read later
- Independent resources are created in parallel; destroy runs in reverse dependency order
- See the graph: `terraform graph` ([02-core-workflow](02-core-workflow.md#terraform-plan))

```hcl
resource "aws_instance" "app" {
  subnet_id  = aws_subnet.a.id               # implicit
  depends_on = [aws_iam_role_policy.s3_read] # explicit, no reference in the arguments
}
```

## Custom conditions (004: 4g)

| Kind | Lives in | Checked | Fails with |
|------|----------|---------|------------|
| `validation` | `variable` block | before planning, on the input value | error, stops |
| `precondition` | `lifecycle` of resource/data, or an `output` | before the object is planned/applied | error, stops that object |
| `postcondition` | `lifecycle` of resource/data | after apply / after a data read; `self` = the object | error, stops dependents (no rollback) |
| `check` (**New (1.5)**) | top-level `check "name"` with `assert`s, optional scoped `data` block | end of plan and apply, and in HCP Terraform health checks | **warning only**, run continues |

```hcl
variable "size" {
  type = string
  validation {
    condition     = contains(["small", "large"], var.size)
    error_message = "size must be small or large."
  }
}

resource "aws_instance" "web" {
  lifecycle {
    precondition {
      condition     = data.aws_ami.web.architecture == "x86_64"
      error_message = "AMI must be x86_64."
    }
    postcondition {
      condition     = self.public_ip != ""
      error_message = "No public IP assigned."
    }
  }
}

check "site_up" {
  data "http" "home" { url = "https://example.com" }
  assert {
    condition     = data.http.home.status_code == 200
    error_message = "Site did not return 200."
  }
}
```

- Sample above validated 2026-11-18 (1.17.0, aws 6.73.0, http 3.6.3)
- Every block needs `condition` (bool) and `error_message`
- Validation/pre/postconditions since 1.2 (validation since 0.13). **New (1.9)**: a `validation` can reference other variables and objects, not only its own variable (checked on 1.17.0: `var.env == "prod" || var.size == "small"` validates)
- A condition must reference something from the config; a constant like `1 == 2` is rejected
- `check` blocks never block apply: use them for ongoing health, use pre/postconditions to stop bad changes

## Sensitive data (004: 4h)

| Mechanism | Hidden in CLI/UI | Kept out of state and plan files | Version |
|-----------|------------------|----------------------------------|---------|
| `sensitive = true` (variable, output) | yes | **no** | 0.15 |
| `ephemeral = true` (variable, child-module output) | no (add `sensitive` too) | yes | **New (1.10)** |
| `ephemeral "type" "name" {}` block (ephemeral resource) | - | yes, value fetched fresh each run | **New (1.10)** |
| write-only argument (`*_wo`, plus `*_wo_version`) | yes | yes, provider uses it then it is dropped | **New (1.11)** |

```hcl
ephemeral "random_password" "db" {             # hashicorp/random, ephemeral version
  length = 20
}

resource "aws_db_instance" "main" {
  # ...
  password_wo         = ephemeral.random_password.db.result
  password_wo_version = 1                       # bump to push a new password
}
```

- Ephemeral values may only flow into: locals, other ephemeral variables/outputs, write-only arguments, ephemeral blocks, provider config, provisioner/connection blocks. Anything else errors, e.g. `terraform_data.input = var.pw` -> "Ephemeral values are not valid for input" (checked on 1.17.0)
- The config above validated with aws 6.73.0 and random 3.9.1 on 1.17.0
- Write-only arguments are never compared, so Terraform cannot detect a change; bump `*_wo_version` to resend
- State and plan files otherwise hold secrets in plain text: use a remote backend with encryption at rest and tight access (HCP Terraform encrypts state; S3 `encrypt = true`), never commit `*.tfstate`, treat saved plans as secret
- Supply secrets via `TF_VAR_x` or a secrets manager instead of hardcoding them in `.tf` or committed `.tfvars`
- **Vault**: the Vault provider reads secrets from Vault (data sources, or **New (1.10)** ephemeral resources such as `vault_kv_secret_v2` so the secret skips state), or issues short-lived dynamic cloud credentials. Example: [`examples/13-vault`](../examples/13-vault); more in [08-ecosystem-tools](08-ecosystem-tools.md)

## Dynamic blocks

- Generate repeated nested blocks (e.g. `ingress`, `tag`, `source`) from a collection instead of writing each one
- `dynamic "<block type>" { for_each = ...  content { ... } }`
- The iterator is named after the block type (`source.key`, `source.value`); rename it with `iterator = x`
- Optional block: `for_each = var.on ? [1] : []`
- Only for nested blocks; for whole resources use `count` / `for_each`

Examples: [`06-dynamic-blocks`](../examples/06-dynamic-blocks) (runs anywhere), [`06-dynamic-blocks/aws-network`](../examples/06-dynamic-blocks/aws-network) (security group `ingress` rules from a list in `locals`)

## For expressions and splat

```hcl
[for s in var.list : upper(s)]                 # [ ] -> tuple
{for s in var.list : s => upper(s)}            # { } -> object, needs key => value
[for k, v in var.map : length(k) + length(v)]  # map: key and value
[for i, v in var.list : "${i} is ${v}"]        # list: index and element
[for s in var.list : upper(s) if s != ""]      # `if` filters elements out
var.servers[*].id                              # splat: short form of [for o in var.servers : o.id]
```

- Input can be a list, set, tuple, map or object
- Unordered to ordered conversion picks an order: maps/objects by key A-Z, sets of strings A-Z, anything else arbitrary
- Splat on a non-list value wraps it in a one-item list; on `null` it returns an empty list/tuple. That makes it handy for optional object variables:

```hcl
variable "website" {
  type    = object({ index_document = string, error_document = string })
  default = null
}

dynamic "website" {
  for_each = var.website[*]          # null -> no block, object -> exactly one block
  content {
    index_document = website.value.index_document
    error_document = website.value.error_document
  }
}
```

- Checked 2026-11-18: this pattern passes `terraform validate` inside an `aws_s3_bucket` (Terraform 1.17.0, aws 6.73.0). But the inline `website` block on `aws_s3_bucket` is **deprecated** since AWS provider v4 (schema marks it deprecated); real code uses the separate `aws_s3_bucket_website_configuration` resource. Keep it only as a splat/dynamic-block illustration

Try these in [`terraform console`](../cheatsheet.md#terraform-console).

## Resource behaviour on apply

| Symbol | Action | When |
|--------|--------|------|
| `+` | create | declared in config, absent from state |
| `-` | destroy | tracked in state, removed from config |
| `~` | update in place | an argument changed and the API allows editing it |
| `-/+` | replace | the API can't edit that argument, so it is destroyed and rebuilt |

## Resources

```hcl
resource "aws_db_instance" "example" {
  # ...
  timeouts {          # only on resource types that offer it
    create = "60m"
    delete = "2h"
  }
}
```

- The resource type (`aws_instance`) picks the kind of infrastructure object and implies the provider
- `timeouts` sets how long an operation may run before it counts as failed. Checked 2026-11-18: the sample validates on `aws_db_instance` (aws 6.73.0), which offers `create`, `update`, `delete`; the allowed keys differ per resource type (see its registry page)
- 004: 4a (`resource` creates/manages, `data` only reads), 4b (`<type>.<name>.<attr>` references)

## Types and values

- Primitive: `string`, `number`, `bool`
- Collection (many values of **one** type): `list`, `map`, `set`
- Structural (several distinct types, needs a schema): `object`, `tuple`
- `null` means "not set", so the provider's own default applies

```hcl
variable "planet"  { type = list(string) }                    # var.planet[0]
variable "plans"   { type = map(string) }                     # var.plans["PlanB"]
variable "person"  { type = object({ name = string, age = number }) }
variable "mixed"   { type = tuple([string, number, bool]) }   # ["a", 15, true]

variable "with_optional" {
  type = object({
    a = string                    # required
    b = optional(string)          # optional, null when omitted
    c = optional(number, 5)       # optional with a default
  })
}
```

- `optional(type, default)` became stable in **1.3** (004: 4d). **003 only**: the experimental `defaults()` function used before that was removed in 1.3 and is now an unknown function (checked in `terraform console`, 1.17.0); put the default as `optional`'s second argument instead
- A **list** is indexed by number, a **map** by key
- A **set** has no index and no order, all values share one type and are converted to match: `toset(["a", "b", 3])` gives `["3", "a", "b"]`
- An **object** is a map with explicit, typed keys; a **tuple** is a list with a type per position

Functions with samples: [cheat sheet](../cheatsheet.md#functions).

## Strings

- Double quotes only; escapes `\n \r \t \" \\ \uNNNN`
- Heredoc: `<<EOT ... EOT`
- `${ }` interpolation, `%{ }` directives (`if`/`for`); literal forms `$${` and `%%{`
- A `~` just inside a directive's braces trims the whitespace around it (`%{ endfor ~}`)

## Operators and conditionals

- Math `* / % + -`, compare `== != < <= > >=`, logic `|| && !`
- Ternary: `condition ? true_val : false_val`. Both branches must be the **same type** (wrap with `tostring()` etc.)

Examples: [`01-variables-outputs-locals`](../examples/01-variables-outputs-locals), [`02-meta-arguments`](../examples/02-meta-arguments), [`03-data-and-expressions`](../examples/03-data-and-expressions)

## Gotchas

- `.tfvars` is Terraform language, not JSON; JSON variant is `.tfvars.json`
- `terraform output` (singular) is the command
- `sensitive` doesn't encrypt anything and doesn't keep values out of state; `ephemeral` / write-only do. `terraform output -json` or `-raw` prints sensitive outputs in clear text
- A failing `check` assertion is a warning; failing validation/pre/postconditions are errors
- Prefer implicit dependencies; `depends_on` is for dependencies Terraform cannot see
