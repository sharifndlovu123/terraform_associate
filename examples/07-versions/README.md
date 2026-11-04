# Versions

Terraform has three things with versions: the **Terraform CLI**, each **provider**, and each registry **module**.
All three follow [semantic versioning](https://semver.org), and you constrain them in the `terraform` block.

## Semantic versioning in one minute

Full spec: **<https://semver.org>**

### How to read a version

The **position** of each number is what gives it meaning: the **first** digit is the **major**, the **second** is the **minor**, the **third** is the **patch**.

```
 3 . 9 . 1
 │   │   └── PATCH   bug fixes only, backwards compatible
 │   └────── MINOR   new features, backwards compatible
 └────────── MAJOR   breaking changes
```

| Going from `3.9.1` to | What changed | Why the other numbers reset |
|-----------------------|--------------|-----------------------------|
| `3.9.2` | a bug fix (patch) | nothing resets |
| `3.10.0` | a new feature (minor) | patch goes back to 0 |
| `4.0.0` | a breaking change (major) | minor and patch go back to 0 |

- Compare each part as a **whole number**, left to right: `3.10.0` is newer than `3.9.1` (10 is bigger than 9), they are not decimals
- This is why `~> 3.6` keeps the first digit (the major, 3) fixed and lets the second and third rise

The same thing as a table, for `3.9.1`:

| Part | Bump it when | Safe to upgrade? |
|------|--------------|------------------|
| `MAJOR` (`3`.x.x) | you make a breaking change | no, read the changelog |
| `MINOR` (x.`9`.x) | you add functionality in a backwards-compatible way | usually |
| `PATCH` (x.x.`1`) | you make a backwards-compatible bug fix | yes |

- A hyphen marks a **pre-release**: `3.7.0-alpha1` sorts *before* `3.7.0`
- A plus marks **build metadata**: `1.0.0+001`, ignored when comparing versions
- `1.x` and up promise stable behaviour; `0.x` makes no such promise

## Constraint operators

| Operator | Meaning | Example | Allows |
|----------|---------|---------|--------|
| `=` (or none) | exactly this version | `= 2.5.3` | only 2.5.3 |
| `!=` | anything except this | `!= 2.6.0` | everything but 2.6.0 |
| `>` `>=` `<` `<=` | comparisons | `>= 1.5.0` | 1.5.0 and above |
| `~>` | "pessimistic": only the **rightmost** part may increase | `~> 3.6` | `>= 3.6.0, < 4.0.0` |
| | | `~> 3.2.0` | `>= 3.2.0, < 3.3.0` |

- Join conditions with a comma, which means AND: `>= 1.5.0, < 2.0.0`
- `~> 3.6` lets minor and patch move; `~> 3.6.0` locks the minor and lets only the patch move
- Pre-releases are skipped unless you ask for that exact version

## What `versions.tf` here does

| What | Constraint | Resolved on 2026-11 |
|------|------------|---------------------|
| Terraform CLI | `>= 1.5.0, < 2.0.0` | any 1.x (this machine: 1.17.0) |
| `random` provider | `~> 3.6` | 3.9.1 (not the 3.7.0-alpha1 pre-release) |
| `null` provider | `~> 3.2.0` | 3.2.4 (3.3.x is excluded) |
| `local` provider | `= 2.5.3` | 2.5.3 |

The "resolved" column changes over time as new releases come out. That is exactly why the lock file exists.

## The lock file: `.terraform.lock.hcl`

- `terraform init` picks the newest version allowed by your constraints, then **records it** (plus checksums) in `.terraform.lock.hcl`
- Later `init` runs reuse the locked version instead of looking for a newer one, so everyone gets the same provider
- **Commit it.** The one in this folder includes checksums for linux, macOS (Apple silicon) and Windows
- It covers providers only, not the Terraform CLI version

```bash
terraform init                 # uses the lock file
terraform init -upgrade        # re-resolves to the newest versions your constraints allow, rewrites the lock
terraform providers            # shows which provider versions the config requires
terraform version              # CLI version plus the installed provider versions
# checksums for other machines' platforms:
terraform providers lock -platform=linux_amd64 -platform=darwin_arm64 -platform=windows_amd64
```

## Errors you will meet (all reproduced here)

**Constraint no longer matches the lock.** Change `random` to `~> 3.6.0` while the lock holds 3.9.1:

```
Error: Failed to query available provider packages
... locked provider registry.terraform.io/hashicorp/random 3.9.1 does not match
configured version constraint ~> 3.6.0; must use terraform init -upgrade to allow selection of new versions
```

Fix: `terraform init -upgrade` (it settles on 3.6.3 and rewrites the lock).

**Nothing satisfies the constraint.** `null` with `~> 9.0`:

```
Error: Failed to query available provider packages
... hashicorp/null: no available releases match the given constraints ~> 9.0
```

**Wrong Terraform CLI.** `required_version = ">= 99.0.0"`:

```
Error: Unsupported Terraform Core version
This configuration does not support Terraform version 1.17.0.
```

## Modules

Registry modules take a `version` argument with the same operators, for example `version = "~> 5.0"`.
Local paths (`./modules/x`) have no version, and git sources pin with `?ref=v1.2.3` instead.

## Try it

```bash
cd examples/07-versions
terraform init
terraform apply
terraform providers
# now edit a constraint in versions.tf and run terraform init again to see the lock file react
```
