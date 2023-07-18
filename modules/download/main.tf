locals {
  release     = var.release
  arch        = var.arch
  system      = var.system
  install_url = "https://raw.githubusercontent.com/rancher/rke2/master/install.sh"
  files = [
    "rke2-images.${local.system}-${local.arch}.tar.gz",
    "rke2.${local.system}-${local.arch}.tar.gz",
    "sha256sum-${local.arch}.txt",
    "rke2-install",
  ]
  assets = { for a in data.github_release.selected.assets : a.name => a.browser_download_url }
}

data "github_release" "selected" {
  repository  = "rke2"
  owner       = "rancher"
  retrieve_by = (local.release == "latest" ? local.release : "tag")
  release_tag = (local.release == "latest" ? "" : local.release)
}

# create a directory to download the files to
# dependency on this resouce forces the external data resource to run at apply time
resource "local_file" "download_dir" {
  filename             = "${path.root}/rke2/README.md"
  content              = <<-EOT
    # RKE2 Downloads
    This directory is used to download the RKE2 installer and images.
    This directory is managed by Terraform, do not modify the contents of this directory.
  EOT
  directory_permission = "0755"
}
# see README.md for more information
data "external" "download" {
  depends_on = [
    data.github_release.selected,
    local_file.download_dir,
  ]
  for_each = toset(local.files)
  program  = ["sh", "${path.module}/file.sh"] # WARNING: requires 'sh' and 'jq' to be installed on the local machine
  query = {
    file = "${path.root}/rke2/${each.key}",
    url  = (each.key == "rke2-install" ? local.install_url : local.assets[each.key]),
  }
}
