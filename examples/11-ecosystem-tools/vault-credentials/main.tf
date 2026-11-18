# Vault hands Terraform short-lived AWS credentials at apply time, so no long-lived
# keys sit on the laptop. Example only: needs a Vault server with the AWS secrets engine
# mounted at "aws" and a role called "deploy".

terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# address and token come from VAULT_ADDR and VAULT_TOKEN
provider "vault" {}

# asks Vault to mint temporary AWS credentials (JIT, expire after the lease)
data "vault_aws_access_credentials" "creds" {
  backend = "aws"
  role    = "deploy"
}

# the AWS provider uses the injected credentials
provider "aws" {
  region     = "us-east-1"
  access_key = data.vault_aws_access_credentials.creds.access_key
  secret_key = data.vault_aws_access_credentials.creds.secret_key
  token      = data.vault_aws_access_credentials.creds.security_token
}

data "aws_caller_identity" "current" {}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}
