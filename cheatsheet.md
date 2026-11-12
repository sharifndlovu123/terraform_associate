# Terraform Cheat Sheet

## CLI

| Command | What it does |
|---------|--------------|
| `terraform init` | Download providers/modules, configure backend (`-upgrade`, `-plugin-dir=PATH`, `-lockfile=MODE`) |
| `terraform get` | Download/refresh modules only (`-update`) |
| `terraform fmt` | Format files to canonical style (`-check`, `-diff`, `-recursive`) |
| `terraform validate` | Check syntax and internal consistency |
| `terraform plan` | Show what would change (`-out=FILE`, `-refresh-only`, `-replace=ADDR`, `-target=ADDR`) |
| `terraform apply` | Make the changes (`-auto-approve`; `apply FILE` runs a saved plan with no prompt) |
| `terraform apply -replace='ADDR'` | Rebuild one resource (replaces deprecated `taint`) |
| `terraform apply -refresh-only` | Update state to match reality (replaces deprecated `refresh`) |
| `terraform import ADDR ID` | Adopt an existing real resource into state, one at a time |
| `terraform destroy` | Tear everything down |
| `terraform show` | Inspect state or a saved plan |
| `terraform output [name]` | Print output values (`-json`, `-raw` for a single string) |
| `terraform apply -var 'k=v'` / `-var-file=f.tfvars` | Set variables from the CLI |
| `terraform workspace list` / `new NAME` / `select NAME` / `show` / `delete NAME` | Manage CLI workspaces (separate state per name) |
| `terraform state list` | List resources in state |
| `terraform state show ADDR` / `mv` / `rm` / `pull` / `push` / `replace-provider` | Inspect, rename/move, forget, download, upload, switch provider |

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

## Resource addresses

`[module path][resource spec]`: `aws_instance.web`, `aws_instance.web[3]` (count), `aws_instance.web["blue"]` (for_each), `module.net.aws_subnet.public`, `data.aws_vpc.main`. Quote them in a shell.

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

# for over a map gives key and value, over a list gives index and element
[for k, v in { b = "xx", a = "y" } : "${k}=${v}"]     # -> ["a=y", "b=xx"] (map keys come out A-Z)
[for i, v in ["hello", "world"] : "${i} is ${v}"]     # -> ["0 is hello", "1 is world"]
{for s in ["hello", "world"] : s => upper(s)}         # -> { hello = "HELLO", world = "WORLD" } ({ } builds an object, needs `=>`)

# short for expression = Splat: [*] is shorthand for a plain "pull one attribute from every element" loop
[{ a = 1 }, { a = 2 }][*].a                           # -> [1, 2]
[for o in [{ a = 1 }, { a = 2 }] : o.a]               # -> [1, 2] (the long form of the line above)
[{ a = 1 }, { a = 2 }].*.a                            # -> [1, 2] (older `.*` spelling, same result)
[{ a = 1, b = [10, 20] }, { a = 2, b = [30] }][*].b[0]  # -> [10, 30] (keeps going after the splat)
var.docker_ports[*].external                          # -> tolist([80]) (works on a list of objects)
values({ x = { a = 1 }, y = { a = 2 } })[*].a         # -> [1, 2] (a map needs values() first)
null[*].a                                             # -> [] (null becomes an empty list)
"solo"[*]                                             # -> ["solo"] (a single value becomes a one-item list)

# arguments: min/max take separate numbers, a list needs `...` to expand
min(20, 200, 12)                                      # -> 12
min([20, 200, 12]...)                                 # -> 12
min([20, 200, 12])                                    # -> Error: Invalid function argument ("numbers" parameter: number required, but have tuple)

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
- `[ ]` around a `for` gives a tuple, `{ }` gives an object (and needs `key => value`)
- Converting an unordered type to an ordered one picks an order: maps/objects by key A-Z, sets of strings A-Z, anything else is arbitrary
- Piping a multi-line heredoc in fails with "Invalid expression" (each line is parsed on its own); stick to single-line expressions when scripting
- `file()` and `path.module` resolve relative to the directory you launched the console from

## Functions

Try any of these in `terraform console` (results shown after `->`).

**Numeric**

```hcl
abs(-12.4)                  # -> 12.4
ceil(5.1)  floor(4.9)       # -> 6   4        (round up / down)
min(20, 200, 12)  max(1, 9) # -> 12  9        (a list needs `...`: min(var.list...))
log(16, 2)                  # -> 4            (log(number, base))
pow(3, 2)                   # -> 9
signum(-13)                 # -> -1           (-1, 0 or 1)
parseint("FF", 16)          # -> 255          (string in the given base -> number)
parseint("12", 2)           # -> Error: not a valid base 2 integer
```

**String**

```hcl
chomp("hello\r\n")                                  # -> "hello"       (trailing newlines)
format("There are %d lights", 4)                    # -> "There are 4 lights"
formatlist("Hello, %s!", ["Ann", "Bo"])             # -> ["Hello, Ann!", "Hello, Bo!"]
indent(2, "a\nb")                                   # -> indents every line except the first
join(", ", ["foo", "bar"])  split(",", "foo,bar")   # -> "foo, bar"   ["foo", "bar"]
lower("HELLO")  upper("hello")  title("hello world") # -> "hello" "HELLO" "Hello World"
regex("^(?P<scheme>[^:]+)://(?P<host>[^/]+)", "https://terraform.io/docs/")   # -> { scheme = "https", host = "terraform.io" }
regexall("[a-z]+", "ab 12 cd")                      # -> ["ab", "cd"]  (list of all matches)
replace("hello world", "/w.*d/", "everybody")       # -> "hello everybody" (/ / makes it a regex)
strrev("hello")                                     # -> "olleh"
substr("hello world", 1, 4)                         # -> "ello"        (offset, length)
trim("?!hello?!", "!?")                             # -> "hello"       (any listed chars, both ends)
trimprefix("helloworld", "hello")                   # -> "world"       (unchanged if no match)
trimsuffix("helloworld", "world")                   # -> "hello"
trimspace("  hello\n\n")                           # -> "hello"
```

**Collection**

```hcl
alltrue([true, "true"])  anytrue([true, false])     # -> true  true   (alltrue([]) is true, anytrue([]) is false)
chunklist(["a","b","c","d","e"], 2)                 # -> [["a","b"], ["c","d"], ["e"]]
coalesce("", "b")                                   # -> "b"          (first non-null, non-empty)
coalescelist([], ["c", "d"])                        # -> ["c", "d"]   (first non-empty list)
compact(["a", "", "b"])                             # -> ["a", "b"]   (drops empty strings)
concat(["a"], ["b", "c"])                           # -> ["a", "b", "c"]
contains(["a", "b"], "a")                           # -> true
distinct(["a", "b", "a"])                           # -> ["a", "b"]
element(["a", "b", "c"], 3)                         # -> "a"          (index wraps around)
index(["a", "b", "c"], "b")                         # -> 1            (position of a value)
flatten([["a", "b"], [], ["c"]])                    # -> ["a", "b", "c"]
keys({ a = 1, c = 2 })  values({ a = 3, c = 2 })    # -> ["a", "c"]   [3, 2]
length("hello")                                     # -> 5            (list, map or string)
lookup({ a = "ay" }, "c", "what?")                  # -> "what?"      (default when key missing)
matchkeys(["i-123","i-abc","i-def"], ["us-west","us-east","us-east"], ["us-east"])   # -> ["i-abc", "i-def"]
merge({ a = "b", c = "d" }, { e = "f", c = "z" })   # -> { a = "b", c = "z", e = "f" } (later wins)
one([])  one(["hello"])                             # -> null  "hello"  (two or more elements is an error)
range(3)  range(1, 10, 3)                           # -> [0, 1, 2]  [1, 4, 7]   (start, limit, step)
reverse([1, 2, 3])                                  # -> [3, 2, 1]
setintersection(["a","b"], ["b","c"])               # -> ["b"]
setunion(["a","b"], ["b","c"], ["d"])               # -> ["a","b","c","d"]
setsubtract(["a","b","c"], ["a","c"])               # -> ["b"]
setproduct(["dev","stg"], ["app1","app2"])          # -> every pairing: [["dev","app1"], ["dev","app2"], ...]
slice(["a","b","c","d"], 1, 3)                      # -> ["b", "c"]   (start inclusive, end exclusive)
sort(["e", "d", "a"])                               # -> ["a", "d", "e"]
sum([10, 13, 6, 4.5])                               # -> 33.5
transpose({ a = ["1","2"], b = ["2","3"] })         # -> { "1" = ["a"], "2" = ["a","b"], "3" = ["b"] }
zipmap(["a", "b"], [1, 2])                          # -> { a = 1, b = 2 }
```

**Type conversion**

```hcl
tonumber("42")  tostring(12)  tobool("true")        # -> 42  "12"  true
toset(["b", "a", "b"])                              # -> toset(["a", "b"])  (dedupes, drops order)
tolist(["a", "b"])  tomap({ a = "x" })              # -> list / map types
try(tonumber("abc"), 0)                             # -> 0            (first expression that doesn't error)
can(tonumber("abc"))                                # -> false        (true/false: does it evaluate?)
type(["a"])                                         # -> tuple([string])   (console only)
sensitive("x")  nonsensitive(sensitive("x"))        # -> mark a value sensitive / unmark it
```

**Encoding**

```hcl
jsonencode({ a = 1, b = ["x"] })                    # -> "{\"a\":1,\"b\":[\"x\"]}"
jsondecode("{\"a\":1}")                             # -> { a = 1 }
yamlencode({ a = 1 })  yamldecode("a: 1")           # -> "\"a\": 1\n"   { a = 1 }
base64encode("hi")  base64decode("aGk=")            # -> "aGk="  "hi"
urlencode("a b&c")                                  # -> "a+b%26c"
```

**Filesystem**

```hcl
file("greeting.txt")                                # -> file contents as a string (error if missing)
fileexists("nope.txt")                              # -> false
fileset(path.module, "*.txt")                       # -> toset(["greeting.txt"])   (set of matching paths)
templatefile("greeting.txt", { name = "Ann" })      # -> file rendered with ${name} filled in
basename("/a/b/c.txt")  dirname("/a/b/c.txt")       # -> "c.txt"  "/a/b"
```

**Date and time**

```hcl
timestamp()                                         # -> current UTC time, changes on every plan
formatdate("YYYY-MM-DD", "2026-11-07T10:00:00Z")    # -> "2026-11-07"
timeadd("2026-11-07T10:00:00Z", "24h")              # -> "2026-11-08T10:00:00Z"
timecmp("2026-11-07T10:00:00Z", "2026-11-08T10:00:00Z")   # -> -1   (-1 earlier, 0 equal, 1 later)
```

**Hash and crypto**

```hcl
md5("hi")                                           # -> "49f68a5c8493ec2c0bf489821c21fc3b"
sha256("hi")                                        # -> hex digest (also sha1, sha512)
base64sha256("hi")                                  # -> "j0NDRmSPa5bfid2pAcUXaxCm2Dlh3TwayItZstwyeqQ="
filemd5("greeting.txt")  filesha256("greeting.txt") # -> hash of a file's contents
uuid()  bcrypt("hi")                                # -> random each call (so the plan changes every time)
```

**IP network**

```hcl
cidrsubnet("10.0.0.0/16", 8, 2)                     # -> "10.0.2.0/24"   (prefix, newbits, netnum)
cidrsubnets("10.0.0.0/16", 8, 8)                    # -> ["10.0.0.0/24", "10.0.1.0/24"]
cidrhost("10.0.0.0/24", 5)                          # -> "10.0.0.5"
cidrnetmask("10.0.0.0/16")                          # -> "255.255.0.0"
```

**Filesystem** (paths in a config are relative to where you run Terraform, so prefer `path.module`)

```hcl
abspath(path.root)                                  # -> absolute path of the root module directory
dirname("foo/bar/baz.txt")                          # -> "foo/bar"
basename("foo/bar/baz.txt")                         # -> "baz.txt"
pathexpand("~/.ssh/id_rsa")                         # -> "/home/<you>/.ssh/id_rsa"  (a path without ~ comes back unchanged)
file("${path.module}/hello.txt")                    # -> "Hello World"  (contents as a string)
fileexists("${path.module}/hello.txt")              # -> true
fileset(path.module, "files/*.txt")                 # -> ["files/hello.txt", "files/world.txt"]  (a set of matching names)
filebase64("${path.module}/hello.txt")              # -> "SGVsbG8gV29ybGQ="
templatefile("${path.module}/backends.tpl", { port = 8080, ip_addrs = ["10.0.0.1", "10.0.0.2"] })
```

`backends.tpl` (uses the same `${ }` and `%{ }` syntax as strings):

```text
%{ for addr in ip_addrs ~}
backend ${addr}:${port}
%{ endfor ~}
```

Renders as `backend 10.0.0.1:8080` and `backend 10.0.0.2:8080` on separate lines.

**Date and time**

```hcl
formatdate("DD MMM YYYY hh:mm ZZZ", "2018-01-02T23:12:01Z")         # -> "02 Jan 2018 23:12 UTC"
formatdate("EEEE, DD-MMM-YY hh:mm:ss ZZZ", "2018-01-02T23:12:01Z")  # -> "Tuesday, 02-Jan-18 23:12:01 UTC"
formatdate("MMM DD, YYYY", "2018-01-02T23:12:01Z")                  # -> "Jan 02, 2018"
formatdate("HH:mmaa", "2018-01-02T23:12:01Z")                       # -> "11:12pm"
timeadd("2017-11-22T00:00:00Z", "10m")                              # -> "2017-11-22T00:10:00Z"  (duration: 10m, 2h, 30s)
timestamp()                                                         # -> current UTC time in RFC 3339, changes every call
```

**Hash and crypto**

```hcl
sha256("hello")   md5("hello")   sha1("hello")   sha512("hello")   # hex digests (md5 and sha1 are weak, avoid for security)
base64sha256("hello")                                              # -> "LPJNul+wow4m6DsqxbninhsWHlwfp0JecwQzYpOLmCQ="
filesha256("${path.module}/hello.txt")                             # hash of a file; also filemd5, filesha1, filesha512, filebase64sha256, filebase64sha512
bcrypt("hello world")                                              # -> "$2a$10$..." (60 chars, random salt: differs every call)
uuid()                                                             # random UUID, differs every call
uuidv5("dns", "example.com")                                       # -> same UUID every time for the same namespace and name
```

Also in this family: `base64sha512`, `filebase64sha512`, `rsadecrypt`.

**IP network**

```hcl
cidrhost("10.12.127.0/20", 16)             # -> "10.12.112.16"   (host number inside the prefix; 268 -> "10.12.113.12")
cidrnetmask("172.16.0.0/12")               # -> "255.240.0.0"
cidrsubnet("172.16.0.0/12", 4, 2)          # -> "172.18.0.0/16"  (prefix, newbits, netnum, see the console section)
cidrsubnet("10.1.2.0/24", 4, 15)           # -> "10.1.2.240/28"
cidrsubnets("10.1.0.0/16", 4, 4, 8, 4)     # -> ["10.1.0.0/20", "10.1.16.0/20", "10.1.32.0/24", "10.1.48.0/20"]
```

`cidrsubnets(prefix, newbits...)` returns consecutive, non-overlapping ranges: one per `newbits` argument, each sized by its own value.

**Type conversion**

```hcl
tobool("true")  tonumber("1")  tostring(true)    # -> true  1  "true"
tolist(["a", "b", 3])                            # -> ["a", "b", "3"]   (mixed values are converted to one type)
tomap({ a = 1, b = 2 })  toset(["a", "b", "c"])
can(local.foo.bar)                               # -> true/false: did the expression evaluate without error?
can(tonumber("abc"))                             # -> false
try(local.foo.baz, "fallback")                   # -> "fallback"  (first argument that does not error)
try(tonumber("abc"), 0)                          # -> 0
sensitive(file("${path.module}/hello.txt"))      # mark a value sensitive: shown as (sensitive value)
nonsensitive(sha256(var.password))               # remove the mark (use only when the result is safe, e.g. a hash)
defaults(...)                                    # old helper for optional() attributes, now removed: use optional(type, default)
```

- `can` and `try` catch evaluation errors such as a missing attribute or a failed conversion. They do not rescue a reference to a name that is not declared at all (that fails earlier)
- A sensitive value that flows into an output must be flagged: `output "x" { value = ..., sensitive = true }`, otherwise Terraform refuses with "Output refers to sensitive values"

Easy to mix up: `coalesce` is for single values, `coalescelist` for lists; `compact` only removes empty **strings**; `contains` works on a list or set, `lookup` on a map; the function is `reverse` (not `reserve`).

## Versions

Read a version by **position**: first digit = **major**, second = **minor**, third = **patch** (`3.9.1`). Spec: <https://semver.org>

- patch bump `3.9.1 -> 3.9.2`: bug fix. minor bump `3.9.1 -> 3.10.0`: new feature, patch resets. major bump `3.9.1 -> 4.0.0`: breaking change, minor and patch reset
- Compare parts as whole numbers: `3.10.0` is newer than `3.9.1`
- `~> 3.6` means `>= 3.6.0, < 4.0.0` (major fixed); `~> 3.6.0` means `>= 3.6.0, < 3.7.0` (major and minor fixed)
- Operators: `=`, `!=`, `>`, `>=`, `<`, `<=`, `~>`; a comma means AND
- `.terraform.lock.hcl` records the exact provider versions chosen: commit it, `terraform init -upgrade` to move it
- Progressive versioning: stay current in small steps and run a nightly `plan`/build as the early warning (see `07-versions/nightly-check.sh`)
- Hands-on version in [`examples/07-versions`](examples/07-versions)

## Packer and Sentinel CLIs

```bash
packer init .          # install plugins from the packer { required_plugins } block
packer fmt .           # also: packer fmt -check .
packer validate .
packer build .         # creates the image (needs cloud credentials)

sentinel test          # run test/<policy>/*.hcl cases against mock data
sentinel test -verbose # rule-by-rule trace and logs
sentinel fmt FILE      # format a policy (takes a file, not a directory)
```

## Private registry modules

- Repo name must be `terraform-<PROVIDER>-<NAME>` (`terraform-aws-demo-bucket`); one module per repo, files at the repo root
- Versions come from **semver git tags** (`v1.0.0`); publish via HCP Terraform -> Registry -> Publish -> Module (needs a connected VCS provider)
- Source address: `<HOSTNAME>/<ORG>/<NAME>/<PROVIDER>` -> `app.terraform.io/devbridge-playground/demo-bucket/aws`; consumers need `terraform login`
- Only registry sources accept `version`; a local path (`../..`) or a plain Git URL ignores/cannot use it
- Registry docs are generated from `README.md`, variable and output `description`s
- Modules pin providers with `>=`; the root module chooses the exact version
- Hands-on: [`examples/08-hcp-terraform/registry-consumer`](examples/08-hcp-terraform/registry-consumer), module repo <https://github.com/sharifndlovu123/terraform-aws-demo-bucket>

## Variable precedence (later wins)

env `TF_VAR_*` < `terraform.tfvars` < `terraform.tfvars.json` < `*.auto.tfvars[.json]` < `-var` / `-var-file`

## Plan symbols

`+` create, `-` destroy, `~` update in place, `-/+` destroy and recreate

## Gotchas

- `apply FILE` (saved plan) skips the approval prompt; `taint` and `refresh` are deprecated for `-replace` and `-refresh-only`
- `state rm` forgets a resource without destroying it; renaming a resource without `state mv` / `moved` destroys and recreates it
- `terraform_remote_state` only exposes root-level outputs, and needs read access to the whole state
- `backend "remote"` with both `name` and `prefix` fails at `init`; use the `cloud` block for HCP Terraform
- `TF_LOG` (or `TF_LOG_CORE` / `TF_LOG_PROVIDER`) plus `TF_LOG_PATH` for logs; a Go panic writes `crash.log`
- `force-unlock` only for your own stuck lock, never someone else's active one
- `.terraform.lock.hcl` = provider dependency lock; `.terraform.tfstate.lock.info` = state lock while a run is active
- `sensitive = true` hides values in the CLI only; they stay in the state file in plain text
- `for_each` needs a map or set: wrap lists in `toset()`
- `count` / `for_each` values must be known at plan time
- Ternary branches must have the same type
- `dev.tfvars` is not autoloaded; `dev.auto.tfvars` is
- Provisioners are a last resort: prefer cloud-init, user_data or baked images
- `remote-exec` and `file` need a `connection` block; use only one of `inline` / `script` / `scripts`
- Provisioners can use `self`; destroy-time ones (`when = destroy`) can only use `self`
- Provider tiers: Official, Verified, Community
