locals {
  tag       = var.release
  type      = local.types[var.type]
  downloads = local.type.downloads
  assets    = { for a in data.github_release.selected.assets : a.name => a.browser_download_url }
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
# why not use the installer to download the proper files?
#  - the installer assumes the system you are running it on is the system you are installing to
#  - the installer uses local system information to determine which files to download
#  - there is a chicken egg issue with downloading the installer and running it in the same terraform apply

data "external" "download" {
  depends_on = [data.github_release.selected]
  # for each download:
  # - use a generic name (file)
  #   - genericizing the file names simplifies the install process
  # - first try to lookup the url from the types.tf, then fallback to the github release assets, finally fallback to an empty string
  #   - this seems backwards, but it allows the types.tf to override the url if needed
  for_each = {
    for a in keys(local.downloads) : local.downloads[a].file => lookup(local.downloads[a], "url", lookup(local.assets, a, ""))
  }
  program = ["sh", "${path.module}/file.sh"] # WARNING: requires 'sh' and 'jq' to be installed on the local machine
  query = {
    file = each.key,
    url  = each.value,
  }
}
resource "local_file" "install" {
  depends_on           = [data.github_release.selected, data.external.download]
  for_each             = data.external.download
  source               = each.value.result.name
  filename             = each.value.result.name
  file_permission      = "0600"
  directory_permission = "0600"
}
