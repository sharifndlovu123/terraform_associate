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
