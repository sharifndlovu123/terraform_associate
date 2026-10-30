# Examples

Every folder is a self-contained config that runs as-is. They only use `terraform_data` (built in) and the
`random`, `local` and `null` providers, so no cloud account or credentials are needed.

```bash
cd examples/<folder>
terraform init
terraform apply
terraform destroy
```

| Folder | Covers |
|--------|--------|
| [`01-variables-outputs-locals`](01-variables-outputs-locals) | variable types, validation, sensitive, `.tfvars` loading, locals, outputs |
| [`02-meta-arguments`](02-meta-arguments) | `count`, `for_each`, `depends_on`, `lifecycle` |
| [`03-data-and-expressions`](03-data-and-expressions) | data source, types, strings, heredoc, directives, operators, conditionals, named values |
| [`04-provisioners`](04-provisioners) | `local-exec`, `null_resource` / `terraform_data` triggers, destroy-time provisioner |
| [`04-provisioners/remote`](04-provisioners/remote) | `connection`, `file`, `remote-exec` (needs an SSH host to apply, validates without one) |
| [`05-modules-and-provider-alias`](05-modules-and-provider-alias) | local module, provider `alias`, passing `providers` to a module |

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
```
