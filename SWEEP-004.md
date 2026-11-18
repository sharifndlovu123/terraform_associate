# 004 Sweep Checklist

The course is the **003** exam. When the sweep is requested: check the current official 004 objectives, then work through this list. Flag 003-only content instead of silently deleting it. Add to this file whenever something dated or uncertain goes into the notes.

**Sweep run 2026-11-18** against the [official 004 review page](https://developer.hashicorp.com/terraform/tutorials/certification-004/associate-review-004). 004 tests **Terraform 1.12**. New objectives: 4f (dependencies), 4g (custom conditions), 4h (sensitive data and Vault), 8c (workspaces and projects). Tools used: Terraform 1.17.0, Packer 1.16.2, Vault 2.2.2. Marker legend in [`notes/00-must-knows.md`](notes/00-must-knows.md#exam-scope-003-vs-004). Open items below still need a real account or tool.

## Beta and new content (the sweep must cover this)
- [x] New features since the 003 course added with `**New (x.y)**` markers (1.4 to 1.14, plus dated HCP items)
- [x] Beta / experimental items labelled: `-generate-config-out` (**Experimental**, still warns on 1.17), `use_lockfile` (experimental in 1.10, GA 1.11), Terraform policy (`tfpolicy`, GA per HashiCorp blog 2026-07-16, still "public beta" in InfoQ 2026-07-31; needs Terraform 1.17+, marked Extra)
- [x] Tested vs extra: `004: <objective>` tags and `Extra, not in 004` (Packer, Consul, Atlantis, CDKTF, Terragrunt, Terratest, `terraform test`, `terraform query`)
- [x] Credit: README credit section now lists the HashiCorp docs and changelogs used

## Whole-repo steps
- [x] 004 objectives compared against `notes/00`..`08`; gaps filled (dependencies, custom conditions, sensitive data, `moved`/`removed`, import blocks, lock file, providers, HCP Explorer / change requests / health / projects / variable sets / run triggers / dynamic credentials)
- [x] "checked on" dates refreshed to 2026-11-18 where re-verified
- [x] Examples re-run on Terraform 1.17.0 in a scratch dir: 01-07, 09 (network/app/partial) and 12 (`terraform test`: 3 passed) applied and destroyed cleanly; 10-packer/docker built, applied, `curl`ed, destroyed; 13-vault applied against a throwaway dev server; all cloud-only configs pass `init -backend=false` + `validate` + `fmt -check`
- [x] README index and credit updated

## Known dated or course-era content
- [x] `notes/07`: course plan names marked **003 only**; plans table rebuilt from hashicorp.com/pricing (legacy Free plan ended 2026-03-31). Docs contradict themselves on policy sets in Free: flagged in the note
- [x] `notes/07`: agent requirements (now ARM64 too, outbound 7146) and Terraform Enterprise (Replicated retired; Docker/Podman/Kubernetes/OpenShift/Nomad; sizing via IBM compatibility report)
- [x] `notes/07`: renamed to HCP Terraform on 2024-04-22; permission sets incl. project roles; cost estimation off by default, legacy policy-checks mode only
- [x] `notes/05`: `cloud` block preferred since 1.1, `backend "remote"` not deprecated but can't be combined with it; `TF_CLOUD_*` env vars (1.2+); workspace-capable backend list matches 1.12 docs; `swift`/`etcdv3`/`artifactory`/`manta` removed in 1.3 (**003 only**); S3 `use_lockfile` GA 1.11, `dynamodb_table` deprecated since 1.11
- [x] `notes/02`: `-get-plugins` removed in 0.15 (1.17 rejects it); `taint` deprecated but still shipped; `refresh` deprecated, no removal planned. All marked
- [x] `notes/06`: `-generate-config-out` still experimental; import blocks gained `for_each` (1.7) and `identity` (1.12)
- [x] `notes/03`: `defaults()` removed in 1.3 (unknown function on 1.17); `timeouts` sample validates on `aws_db_instance`; `website[*]` sample validates but the inline `website` block is deprecated in the AWS provider (caveat added)
- [x] `cheatsheet.md`: functions re-checked, new ones added (1.3-1.10), `md5`/`sha1` collision warning still in the 1.12 docs
- [x] `notes/04`: publishing rules and source forms checked against current registry docs; "Verified" is now "Partner"

## Unverified against real services (re-test if possible)
- [ ] `remote` and `cloud` backends, and S3 native locking (`use_lockfile`): docs-checked only, no live run
- [x] S3 backend: user confirmed it worked in a previous project (not re-run in this repo)
- [x] `azurerm` backend (Azure Storage): user confirmed it worked in a previous project (not re-run here)
- [ ] HCP Terraform / Enterprise behaviour: notes now match current docs, but nothing was run against HCP
- [ ] `examples/08-hcp-terraform/sentinel`: passed `sentinel test` with CLI 0.41.0 earlier; the CLI is no longer on PATH, so not re-run in the sweep. Still run it in a real policy set. 004 (8b) lists policy enforcement generally, with both Sentinel and OPA in its docs and tutorials
- [x] Sentinel CLI licence: proprietary; release zip holds `EULA.txt` (internal use) and `TermsOfEvaluation.txt` (30-day non-production). Free local testing is my reading of the EULA, not a stated rule (noted in `notes/07`)
- [x] Terraform policy (`tfpolicy`) and its enforcement levels: documented as Extra (needs 1.17+, 004 targets 1.12). Not tried
- [x] `examples/10-packer`: Packer is not in the 004 objectives (Extra). AMI template still validates (Packer 1.16.2); AMI build never run
- [x] `examples/10-packer/docker`: rebuilt 2026-11-18 (Packer 1.16.2, docker plugin 1.1.5), applied, `curl` returned the page, destroyed, image removed
- [ ] `examples/08-hcp-terraform/sentinel`: `tfplan-functions` path confirmed (repo says it is moving to the Terraform Registry). Current Sentinel docs show `import "module"` in config, not the `module` block used in `sentinel.hcl`: confirm which form a real HCP policy set accepts (needs an HCP account)
- [x] Course "Terraform Cloud" / Team & Governance naming: handled in `notes/07`
- [x] `notes/08` callouts re-verified 2026-11-18: CDKTF archived; Atlantis CNCF Sandbox; Terragrunt 1.2.2 with `run --all`; Kitchen-Terraform archived, InSpec and terraform-compliance active; Vault provider 5.x
- [ ] `examples/11-ecosystem-tools`: consul and vault-credentials `validate` on 1.17.0; Terragrunt still never run (see the blocked tool runs below)
- [x] `examples/12-testing`: 3 tests pass on 1.17.0. `terraform test` is not in the 004 objectives (Extra). `mock_provider` / `override_` blocks not added
- [x] `examples/13-vault`: original applies on 1.17.0 (secret appears 5 times in state). Vault provider is now 5.13.0 and **deprecates** the `vault_kv_secret_v2` / `vault_generic_secret` data sources for the ephemeral resource. New `ephemeral/` example (ephemeral read + write-only argument) tested: secret appears 0 times in state. 004 tests this (4h). `main.tf` still pins `~> 4.0` on purpose; state stays gitignored
- [x] Resolved by research 2026-11-18: identity in `import` blocks is in the 1.12.0 changelog (`state identities` is in the v1.12.x docs, so also 1.12); Explorer GA Feb 2024, change requests GA Feb 2025; Azure/GCP cost-estimation lists added to `notes/07`; archived official 003 objectives confirm no provisioners or CLI workspaces
- [ ] Free-plan policy enforcement: HashiCorp's own pages contradict each other (flagged in `notes/07`); recheck later
- [ ] Tool runs blocked in this session (downloading new binaries needs your OK): Terraform **1.12** (the exam version: re-run examples, check `import` blocks in child modules), Sentinel CLI re-run of `sentinel test`, Terragrunt, and S3 `use_lockfile` against a local MinIO with fake credentials
