output "zip_path" {
  value = data.archive_file.bundle.output_path
}

output "zip_size_bytes" {
  value = data.archive_file.bundle.output_size
}

output "expected_entries" {
  value       = length(var.files) + length(var.extra_files) + length(var.placeholder_files) + (var.include_license ? 1 : 0)
  description = "How many source blocks the dynamic blocks should generate"
}
