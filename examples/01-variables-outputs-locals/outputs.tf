output "tags" {
  value       = terraform_data.app.output.tags
  description = "Common tags applied to everything"
}

output "db_password" {
  value     = var.db_password
  sensitive = true # hidden in the terminal, still plain text in the state file
}
