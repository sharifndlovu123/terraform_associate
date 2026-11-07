# HCP Terraform dummy: S3 bucket test

Tiny test config: one S3 bucket (created by the `demo-bucket` module from the private registry), with state stored in HCP Terraform via the `cloud` block
(org `devbridge-playground`, workspace `default-workstation`).

## Reminder: remote execution needs its own credentials

If the workspace Execution Mode is **Remote** (the default), `terraform plan` / `apply` from the CLI
only uploads the config. **HCP Terraform runs it on its own workers**, not on this machine.

- Those workers cannot see your local `aws` CLI login or any env vars in your shell.
- You must add the credentials as **workspace variables**:
  Workspace -> Variables -> add as **Environment variables** (category `env`), marked **Sensitive**:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - (`AWS_SESSION_TOKEN` too, if using temporary credentials)
- Symptom if missing: the remote run fails with "No valid credential sources found" / auth errors.

Alternative: set Execution Mode to **Local** (Workspace -> Settings -> General). The run then happens
on this machine using local credentials, and HCP Terraform only stores the state.

## Status note: no state in HCP Terraform yet

As of 2026-11-07 the workspace has **no state file**. That is expected:

- `terraform init` only connects to the workspace; it does not create state.
- `plan` (or a failed run) does not create state either.
- The first state version appears after the first successful `terraform apply`
  (Workspace -> States tab). Until then the workspace is empty.

## Exam angle

- `cloud` block = HCP Terraform integration (state storage, remote runs, variables, locking).
- Remote execution uses workspace variables; local execution uses your own environment.
- Terraform variables (`category = terraform`) and environment variables (`category = env`) are different things.

## Cleanup

`terraform destroy` removes the bucket (the module defaults `force_destroy = true`).

Because the config now uses a registry module, `terraform init` also downloads `devbridge-playground/demo-bucket/aws` 1.x; the workspace needs `terraform login` locally, and remote runs fetch it with the org's own access.

## Private registry demo module (separate repo)

The demo module lives in its **own repo, outside this study repo**:
`~/Documents/vs_code/personal/terraform-aws-demo-bucket` (one commit on `main`).

The HCP Terraform private registry publishes a module from a VCS repo (one module per repo, files at
the repo root, repo named `terraform-<PROVIDER>-<NAME>`), which is why it is split out.

- GitHub (private): <https://github.com/sharifndlovu123/terraform-aws-demo-bucket>, tagged `v1.0.0`.
  Published to the `devbridge-playground` private registry as `demo-bucket` / `aws`.
- To consume it, see `../registry-consumer/` (written but deliberately not run).
- The registry docs (inputs, outputs, readme) are generated from the module's `README.md`,
  `variables.tf` and `outputs.tf`, so the descriptions there are what you will see.
