output "downloaded_assets" {
  value       = (local.local_file_path == "" ? module.download[0].assets : null)
  description = <<-EOT
    A list of the GitHub assets that were downloaded.
    This will be null if a local file path was set.
  EOT
}
output "expected_files" {
  value       = local.expected_files
  description = <<-EOT
    A list of the files that are expected to be present after the download phase.
    This is static, and is handy to use if you are generating a local file copy.
  EOT
}
