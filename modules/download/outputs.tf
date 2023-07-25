output "assets" {
  value = local.assets
}
output "files" {
  value = local.files
}
output "tag" {
  value = data.github_release.selected.release_tag
}