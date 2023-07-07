output "assets" {
  value = data.github_release.selected.assets
}
output "arch" {
  value = local.type.arch
}
output "type" {
  value = keys(local.type)[0]
}
# output "downloaded" {
#   value = data.external.download
# }