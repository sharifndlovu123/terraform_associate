terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.0"
    }
  }
}

# Address is set directly; the token is still read from VAULT_TOKEN env var
provider "vault" {
  address = "http://127.0.0.1:8200"
}

data "vault_kv_secret_v2" "aws_creds" {
  mount = "secret"
  name  = "aws"
}

# or use path
data "vault_generic_secret" "aws_creds_generic" {
  path = "secret/aws"
}

# sensitive = true hides the value in CLI output, but it is still stored
# in plaintext in terraform.tfstate. Reveal one with: terraform output aws_key
output "aws_key" {
  value     = data.vault_kv_secret_v2.aws_creds.data["aws-key"]
  sensitive = true
}

output "aws_access" {
  value     = data.vault_kv_secret_v2.aws_creds.data["aws-access"]
  sensitive = true
}

# Not secret, so it can be printed normally. nonsensitive() strips the flag
# that the data source puts on every value it returns.
output "aws_region" {
  value = nonsensitive(data.vault_kv_secret_v2.aws_creds.data["aws-region"])
}

output "user" {
  value = nonsensitive(data.vault_kv_secret_v2.aws_creds.data["user"])
}
