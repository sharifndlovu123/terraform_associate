# Newer way (004 objective 4h): read the secret EPHEMERALLY so it never lands in plan or state.
# Same dev server and secret as ../main.tf. Tested with Terraform 1.17.0 and vault provider 5.13.0:
# after apply, `grep FAKEKEY terraform.tfstate` finds nothing (the data source version in ../ stores it).

terraform {
  required_version = ">= 1.11" # ephemeral resources need 1.10+, write-only arguments 1.11+
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.0" # v5 deprecates the vault_kv_secret_v2 / vault_generic_secret data sources for this
    }
  }
}

provider "vault" {
  address = "http://127.0.0.1:8200"
}

# ephemeral block: read on every plan/apply, used, then thrown away. Never saved.
ephemeral "vault_kv_secret_v2" "aws_creds" {
  mount = "secret"
  name  = "aws"
}

# An ephemeral value can only go to places that are not saved: provider blocks, locals,
# other ephemeral blocks, ephemeral outputs, or WRITE-ONLY arguments (names end in _wo).
# Here it is copied to a second secret through a write-only argument.
resource "vault_kv_secret_v2" "copy" {
  mount        = "secret"
  name         = "aws-copy"
  data_json_wo = jsonencode(ephemeral.vault_kv_secret_v2.aws_creds.data)

  # Terraform cannot diff a value it never stored, so bump this number to send a new value
  data_json_wo_version = 1
}

# A real use: configure another provider without the key ever touching state, e.g.
# provider "aws" {
#   access_key = ephemeral.vault_kv_secret_v2.aws_creds.data["aws-access"]
#   secret_key = ephemeral.vault_kv_secret_v2.aws_creds.data["aws-key"]
# }
