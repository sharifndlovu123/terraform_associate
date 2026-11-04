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

## Upgrading progressively: a nightly canary

Pinning keeps you safe but lets you fall behind; floating to the newest keeps you current but breaks you at random.
Do both: **pin what deploys, float a copy that only tests.**

```
 deploys (dev / staging / prod)      nightly canary, e.g. 02:00
 -------------------------------     ---------------------------------------------
 use the committed lock file         ignore the lock file
 same versions every time            init -upgrade: newest versions the constraints allow
                                     validate, then plan
                                              |
                              red: something upstream broke overnight
                                   -> read the failure in the morning and fix it
                              green: refresh the lock file in a PR
                                   -> promote dev -> staging -> prod
```

- You find out about a breaking release **the morning after it ships**, not on the day you needed to deploy
- Constraints set the blast radius: with `~> 3.6` the canary can pick up new minors and patches, but never `4.0.0`; a major upgrade stays a deliberate edit
- The same idea works for the Terraform CLI: also run the canary on the newest Terraform release

[`nightly-check.sh`](nightly-check.sh) is a working version of the canary. It copies the config **without** the lock file into a temp dir, runs `init -upgrade`, then `validate` and `plan`:

```bash
./nightly-check.sh        # exit 0 = still works, exit 1 = broken
```

```
==> versions that moved since the committed lock file
    random: 3.6.3 -> 3.9.1            # shown when the lock is behind
==> validate
==> plan
OK: the newest allowed versions still work.
    Safe to refresh the lock file: terraform init -upgrade, then commit .terraform.lock.hcl
```

```
BROKEN: validate failed on the newest allowed versions. Fix it in the morning (update the code, or tighten a constraint).
```

Checked here with a current lock file, a stale lock file, a config that fails `validate` and one that fails `plan`.
`plan` exiting 2 (changes to make) counts as healthy: the canary only cares that planning *works*.
In real use, point the plan at a non-production environment with real state and credentials. Here the state is empty, so it plans two creates.

**When it goes red**

1. Read the failure and work out which provider or version caused it (the "versions that moved" lines tell you)
2. Fix your code for the new behaviour, **or** hold back the bad release: `~> 3.6` -> `~> 3.6.0`, or `version = "~> 3.6, != 3.9.1"`
3. If it is an upstream bug, keep the exclusion until a fixed release comes out, then relax the constraint again

**Scheduling it** (sketches, not run here):

```bash
# cron: 02:00 every night, alert on failure
0 2 * * * /path/to/examples/07-versions/nightly-check.sh || /path/to/notify-me.sh
```

```yaml
# GitHub Actions
on:
  schedule:
    - cron: "0 2 * * *"
jobs:
  canary:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      - run: examples/07-versions/nightly-check.sh
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
