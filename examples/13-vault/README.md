# 13 Vault

Terraform reads secrets from Vault with a **data source**. Free and local: a Vault dev server, a KV v2 secret, and a config that reads it into outputs. Applied with Terraform 1.17.0, Vault 2.2.2 and vault provider 4.8.0.

An extra alongside the course, based on the HashiCorp tutorial [Inject secrets into Terraform using the Vault provider](https://developer.hashicorp.com/terraform/tutorials/secrets/secrets-vault).

## Run it

**Terminal 1**: start a dev server. It runs in memory, is unsealed, and loses everything when stopped. Never use it for anything real.

```bash
vault server -dev -dev-root-token-id="playground"
```

**Terminal 2**: point the CLI and Terraform at the server, then save a secret. You can also use the UI at http://127.0.0.1:8200 (sign in with token `playground`) under the `secret/` KV engine.

```bash
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='playground'    # token auth is the simplest for a demo; the provider reads it from this env var

vault kv put secret/aws aws-key=FAKEKEY aws-access=FAKEACCESS aws-region=us-east-1 user=demo
vault kv get secret/aws

terraform init
terraform apply
terraform output              # sensitive outputs show as <sensitive>
terraform output aws_key      # naming one output reveals it
```

## What `main.tf` shows

| Block | Shows |
|-------|-------|
| `provider "vault"` | `address` set in the config; the token comes from `VAULT_TOKEN`, so no credential is in the code |
| `data "vault_kv_secret_v2"` | reads a KV **v2** secret by `mount` (`secret`) and `name` (`aws`); values are in `.data["key"]` |
| `data "vault_generic_secret"` | the older generic way: one `path` (`secret/aws`) |
| `output ... sensitive = true` | hides the value in CLI output |
| `nonsensitive()` | removes the sensitive flag from values that are not secret (region, user), so they print normally |

## Exam points

- The data source marks the secret values **sensitive**. An output that uses one is rejected unless it has `sensitive = true` or wraps the value in `nonsensitive()`.
- `sensitive = true` only hides the value **on screen**. The secret is still in **plain text in `terraform.tfstate`**, so protect state with a remote backend that has encryption and access control. Here `*.tfstate` is gitignored.
- A data source is a read-only lookup: Terraform reads the secret on every plan/apply and never creates or deletes it, the same as `data "aws_ami"` in [`10-packer`](../10-packer).
- KV v2 keeps secrets under `secret/data/aws` in the API. `vault_kv_secret_v2` adds the `data/` part for you from `mount` and `name`.

## Newer (not in the 003 course)

Terraform 1.10+ adds **ephemeral resources**, such as `ephemeral "vault_kv_secret_v2"`. They read the secret for each run and never store it in plan or state. Terraform 1.11+ adds **write-only arguments** to pass such values into resources. Not tried here yet; see `SWEEP-004.md`.

## Clean up

Stop the dev server (Ctrl+C) and the secrets are gone. Delete `terraform.tfstate` too, because it still holds them.
