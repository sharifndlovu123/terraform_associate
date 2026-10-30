# Configuration

## Input variables

Arguments you can set: `type`, `default` (having one makes the variable optional), `description`, `validation`, `sensitive`.
Declared in the root module or in child modules.

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

- `output "name" { value, description, sensitive }`
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

- **`depends_on`**: declare an ordering Terraform can't work out from references
- **`count`**: stamp out N copies; `count.index` is zero-based; needs a whole number known at plan time
- **`for_each`**: one instance per map entry or set element (`each.key`, `each.value`); lists must go through `toset()`
- **`provider`**: pick an aliased provider (`provider = aws.eu`)
- **`lifecycle`**: `create_before_destroy`, `prevent_destroy`, `ignore_changes`

## Resource behaviour on apply

| Symbol | Action | When |
|--------|--------|------|
| `+` | create | declared in config, absent from state |
| `-` | destroy | tracked in state, removed from config |
| `~` | update in place | an argument changed and the API allows editing it |
| `-/+` | replace | the API can't edit that argument, so it is destroyed and rebuilt |

## Types and values

- Primitive: `string`, `number`, `bool`
- Collection/structural: `list` (tuple), `map` (object)
- `null` means "not set", so the provider's own default applies

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
- `sensitive` doesn't encrypt anything
