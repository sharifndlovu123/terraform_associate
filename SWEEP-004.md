# 004 Sweep Checklist

The course is the **003** exam. When the sweep is requested: check the current official 004 objectives, then work through this list. Flag 003-only content instead of silently deleting it. Add to this file whenever something dated or uncertain goes into the notes.

## Beta and new content (the sweep must cover this)
- [ ] Look for features that are new since the 003 course and add them in short notes with a "new" marker and the version they arrived in
- [ ] Mention beta, experimental and tech-preview features (for example `-generate-config-out`) and label them clearly as such, so nobody mistakes them for stable or exam material
- [ ] Say which of the new items 004 actually tests and which are extra reading
- [ ] Credit official release notes or docs for anything added, in my own words, and keep the README credit section current

## Whole-repo steps
- [ ] Compare the 004 exam objectives against `notes/00`..`07` and note anything missing or renamed
- [ ] Re-check every "checked on <date>" line and version number
- [ ] Re-run the examples in a scratch dir with the current Terraform version
- [ ] Update the README index and credit if files change

## Known dated or course-era content
- [ ] `notes/07-hcp-terraform.md`: "Course-era plan names" (Free / Teams & Governance / Business / Enterprise) vs the plans table
- [ ] `notes/07-hcp-terraform.md`: agent requirements (OS, memory, disk, hostnames) and Terraform Enterprise sizing and supported OS
- [ ] `notes/07-hcp-terraform.md`: "HCP Terraform" vs "Terraform Cloud" naming, permission sets, cost-estimation resource list
- [ ] `notes/05-state.md`: `backend "remote"` (older) vs `cloud` block; list of backends supporting workspaces; S3 locking (DynamoDB works per the user's earlier project; native `use_lockfile` unverified)
- [ ] `notes/02-core-workflow.md`: `taint` (deprecated), `-get-plugins` (removed), `terraform refresh` (deprecated)
- [ ] `notes/06-maintain-infrastructure.md`: `-generate-config-out` is experimental; import block behaviour
- [ ] `notes/03-configuration.md`: `defaults()` removed in favour of `optional(type, default)`; unverified `timeouts` and `website[*]` dynamic block samples
- [ ] `cheatsheet.md`: function list, `md5`/`sha1` weakness notes, anything marked deprecated
- [ ] `notes/04-modules.md`: registry publishing rules and source address forms

## Unverified against real services (re-test if possible)
- [ ] `remote` and `cloud` backends, and S3 native locking (`use_lockfile`)
- [x] S3 backend: user confirmed it worked in a previous project (not re-run in this repo). Re-test live during the sweep if possible
- [x] `azurerm` backend (Azure Storage): user confirmed it worked in a previous project (not re-run here). Re-test live during the sweep if possible
- [ ] HCP Terraform / Enterprise behaviour (taken from the course only)
- [ ] `examples/08-hcp-terraform/sentinel`: Sentinel policy passes `sentinel test` (CLI 0.41.0) on hand-written mocks; still run it in a real policy set with real plan data. Also check whether 004 expects OPA alongside Sentinel
- [ ] Sentinel CLI licence terms are not stated in the CLI docs: confirm them, and confirm which plans include policy enforcement today
- [ ] Enforcement levels: the newer "Terraform policy" language (Advisory / Mandatory overridable / Mandatory) is from the docs only; check whether 004 covers it and try it
- [ ] `examples/10-packer`: AMI template validated with Packer 1.16.2 and the amazon plugin 1.8.4 only; the course slide template had no `required_plugins` block (added). AMI `packer build` never run. Check the Packer coverage in 004 and the version pinned in `required_plugins`
- [x] `examples/10-packer/docker`: free Docker-builder version actually built (Packer 1.16.2, docker plugin 1.1.5) and applied with kreuzwerker/docker ~> 3.0 on Terraform 1.17.0, checked with `curl`, then destroyed. Re-run during the sweep to catch plugin or provider changes
- [ ] `examples/08-hcp-terraform/sentinel`: `tfplan-functions` helper module comes from HashiCorp's `terraform-sentinel-policies` repo (downloaded, not vendored); confirm the URL and how an HCP policy set should reference it (`module` block source)
- [ ] Course slides call the platform "Terraform Cloud" and sell Sentinel with Team & Governance: recheck names and plan tiers
- [ ] `notes/08-ecosystem-tools.md`: slides are 003-era. Re-verify the "Newer" callouts: CDKTF archived 2025-12-10 (successors and migration advice), Atlantis now CNCF Sandbox (not HashiCorp), Terragrunt 1.x CLI changes (`run --all`), ephemeral values and Vault ephemeral resources (Terraform 1.10+), Kitchen-Terraform / InSpec / terraform-compliance still maintained?
- [ ] `examples/11-ecosystem-tools`: consul and vault-credentials only `validate`d (no server); terragrunt.hcl never run (binary download was blocked). Install Terragrunt and run it during the sweep
- [ ] `examples/12-testing`: `terraform test` verified on 1.17.0; check `mock_provider`, `override_` blocks and newer test features, and whether 004 covers `terraform test`
- [ ] `examples/13-vault` (work in progress): reads KV v2 secrets from a `vault server -dev` with `vault_kv_secret_v2` and `vault_generic_secret`; vault provider pinned `~> 4.0` (4.8.0 locked), applied against Vault 2.2.2. Check the current provider major version, and add the newer way to keep secrets out of state (ephemeral resources, Terraform 1.10+, and write-only arguments, 1.11+). Confirm whether 004 tests them. `terraform.tfstate` there holds the secrets in plain text: it is gitignored (`*.tfstate`), keep it that way
