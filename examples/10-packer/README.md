# 10 Packer

Example only. Packer builds an image once, Terraform then launches it. Nothing here was built or applied (a build creates a real AMI and needs AWS credentials); it was checked with `packer init`, `packer fmt -check`, `packer validate` and `terraform validate`.

```bash
packer init .          # installs the amazon plugin (needs internet, no AWS credentials)
packer fmt -check .
packer validate .
packer build .         # NOT run: needs AWS credentials, creates an AMI
cd terraform && terraform init && terraform validate
```

| File | Shows |
|------|-------|
| `web.pkr.hcl` | `packer` block with `required_plugins`, `variable`, `locals`, `source "amazon-ebs"`, `build` with a `shell` provisioner and a `shell-local` post-processor |
| `script/script.sh` | the script the provisioner runs on the temporary instance |
| `terraform/main.tf` | `data "aws_ami"` (`most_recent`, `name_regex`, `owners`) feeding an `aws_instance` |

Packer is a tool you run (by hand or from a build server), not a service, so Terraform only ever *references* the finished image through a data source. The Packer `ami_name` (`my-server-httpd`) and the Terraform `name_regex` (`^my-server-httpd`) must match. With numbered builds such as `myami-001`, `myami-002` use a regex like `^myami-\\d{3}`, and `most_recent = true` picks the newest.
