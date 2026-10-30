output "servers" {
  value = terraform_data.server[*].output
}

output "groups" {
  value = { for k, g in terraform_data.group : k => g.output.location }
}

output "users" {
  value = keys(terraform_data.user)
}
