locals {
  tag               = var.release
  type              = local.types[var.type]
  file_names        = keys(local.type.downloads)
  file_designations = values(local.type.downloads)
}

data "github_release" "selected" {
  repository  = "rke2"
  owner       = "rancher"
  retrieve_by = "tag"
  release_tag = local.tag
}

# why external provider?
#  - http provider has a max download size of 100MB (images archive is > 1GB)
#  - null resources would need a trigger to run when a file is deleted outside of terraform
#  - basically, I couldn't find a way to download files like this with the built-in providers
# what are the trade-offs?
#  - external provider requires a script to be run on the local machine (the machine running terraform)
#  - external provider requires the local machine to have the required tools installed
#  - external provider requires the local machine to have access to the internet
#  - external provider is a "data" resource, so it runs at plan/refresh/compile time, not apply time

# external provider resource runs a script that verifies the files and downloads them using wget if they are missing
# make a map of file_name => download_url from the list of assets in the release, filter by the type.downloads list
# the local_file objects will be keyed by the file_name eg. local_file["rke2-images.linux-amd64.tar.gz"]
# this script is idempotent, it will not download files that already exist
data "external" "file" {
  depends_on = [data.github_release.selected]
  for_each   = { for a in data.github_release.selected.assets : a.name => a if contains(local.file_names, a.name) }
  program    = ["sh", "${path.module}/file.sh"] # WARNING: requires 'sh', 'jq', 'md5sum' and 'awk' to be installed on the local machine
  query = {
    # this normalizes the file names so that we can use the same logic for all types
    file = local.type.downloads[each.key],
    url  = each.value.browser_download_url,
  }
}

# make a map of file_name => download_url from the list of assets in the release, filter by the type.downloads list
# the local_file objects will be keyed by the file_name eg. local_file["rke2-images.linux-amd64.tar.gz"]
resource "local_file" "assets" {
  depends_on = [data.github_release.selected, data.external.file]
  for_each   = { for a in data.github_release.selected.assets : a.name => a if contains(local.file_names, a.name) }
  # must use source here because images archive is too large for local_file to read
  # tmp files should never actually be created, this prevents a race condition at compile/plan/refresh time
  # designation normalizes the file names so that we can use the same logic for all types
  source               = (fileexists(local.type.downloads[each.key]) ? local.type.downloads[each.key] : "${each.key}_tmp")
  filename             = (fileexists(local.type.downloads[each.key]) ? local.type.downloads[each.key] : "${each.key}_tmp")
  file_permission      = "0600"
  directory_permission = "0600"
}
