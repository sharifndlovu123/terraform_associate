# 09 Backends and remote state

Runs offline: only the `local` backend and the built-in `terraform_data` resource.

```bash
terraform -chdir=network init && terraform -chdir=network apply -auto-approve
terraform -chdir=app init     && terraform -chdir=app apply -auto-approve   # shows the network stack's subnet_id
terraform -chdir=partial init -backend-config=backend.hcl                   # state lands in elsewhere.tfstate
```

| Folder | Shows |
|--------|-------|
| `network` | `backend "local"` with a custom `path`, a root output other stacks can read |
| `app` | `terraform_remote_state` reading that output, `optional()` object attributes |
| `partial` | empty `backend` block completed with `-backend-config=FILE` |

Clean up with `terraform -chdir=<folder> destroy` and delete the generated `state/`, `.terraform/` and `*.tfstate` (all git-ignored).
