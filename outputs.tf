output "downloaded_assets" {
  value = (local.local_file_path == "" ? module.download[0].assets : null)
}
output "config" {
  value = (local.rke2_config == "" ? null : module.install.config)
}