output "downloaded_assets" {
  value = (local.local_file_path == "" ? module.download[0].assets : null)
}
output "expected_files" {
  value = local.expected_files
}
