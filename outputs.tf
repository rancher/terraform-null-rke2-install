output "downloaded_assets" {
  value = (local.local_file_path == "" ? module.download[0].assets : null)
}
# output "downloaded" {
#   value = module.download.downloaded
# }