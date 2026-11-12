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
| `s3-bucket` | S3 bucket with public access block, versioning, encryption and sample bucket policies (**example only, not applied**; needs AWS) |

`s3-bucket` was only checked with `terraform validate`. Its policies: HTTPS only, deny unencrypted uploads and read-only role (all three merged into the one attached policy), plus alternatives for an office IP range, cross-account upload and CloudFront read (`jsonencode`). A bucket takes a single policy, so combine documents with `source_policy_documents`.

Clean up with `terraform -chdir=<folder> destroy` and delete the generated `state/`, `.terraform/` and `*.tfstate` (all git-ignored).
