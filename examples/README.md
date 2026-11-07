# Examples

Every folder is a self-contained config that runs as-is. They only use `terraform_data` (built in) and the
`random`, `local`, `null` and `archive` providers, so no cloud account or credentials are needed.
The one exception is [`06-dynamic-blocks/aws-network`](06-dynamic-blocks/aws-network), which describes real AWS resources: `terraform init` and `terraform validate` work anywhere, but `apply` needs AWS credentials.

```bash
cd examples/<folder>
terraform init
terraform apply
terraform destroy
```

| Folder | Covers |
|--------|--------|
| [`01-variables-outputs-locals`](01-variables-outputs-locals) | variable types (`list`, `map`, `object`), validation, sensitive, `.tfvars` loading and overriding, locals, `for` expressions, outputs |
| [`02-meta-arguments`](02-meta-arguments) | `count`, `for_each`, `depends_on`, `lifecycle` |
| [`03-data-and-expressions`](03-data-and-expressions) | data source, types, strings, heredoc, directives, operators, conditionals, named values |
| [`04-provisioners`](04-provisioners) | `local-exec`, `null_resource` / `terraform_data` triggers, destroy-time provisioner |
| [`04-provisioners/remote`](04-provisioners/remote) | `connection`, `file`, `remote-exec` (needs an SSH host to apply, validates without one) |
| [`05-modules-and-provider-alias`](05-modules-and-provider-alias) | local module, provider `alias`, passing `providers` to a module |
| [`09-backends-and-remote-state`](09-backends-and-remote-state) | `backend "local"` with a custom path, `terraform_remote_state` reading another stack's output, partial backend config (`-backend-config=FILE`), `optional()` object attributes |
| [`08-hcp-terraform`](08-hcp-terraform) | the `cloud` block that points a config at HCP Terraform (validates offline, `init` needs a real organisation); `dummy/` is an S3 bucket test with state in HCP Terraform; `registry-consumer/` calls a module from the private registry (needs `terraform login`, not run) |
| [`07-versions`](07-versions) | semantic versioning (major.minor.patch), `~>` and other constraint operators, `required_version`, the `.terraform.lock.hcl` file, common version errors, a nightly canary script that finds breaking releases overnight |
| [`06-dynamic-blocks/aws-network`](06-dynamic-blocks/aws-network) | AWS VPC, public subnets, internet gateway and default route, security group whose `ingress` rules come from a `dynamic` block (config in `locals`, no variables) |
| [`06-dynamic-blocks`](06-dynamic-blocks) | `dynamic` blocks: iterate a map, custom `iterator`, a set (key = value), optional block via `[1]` / `[]` |

Things to try:

```bash
# 01: variable precedence and validation
terraform apply -var-file=prod.tfvars
terraform apply -var environment=staging      # fails validation
TF_VAR_environment=prod terraform apply       # env var, overridden by terraform.tfvars if it also sets it

# 02: count as a switch
terraform apply -var enable_extra=true
terraform apply -var server_count=5

# 03: print outputs in different formats
terraform output
terraform output -json
terraform output -raw data_source

# 04: change the trigger and watch the provisioners re-run
terraform apply -var release=v2

# 06: toggle an optional block, then list the zip entries
terraform apply -var include_license=true
python3 -c "import zipfile; print(zipfile.ZipFile('build/bundle.zip').namelist())"
```
