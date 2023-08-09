locals {
  release     = var.release
  install_url = "https://raw.githubusercontent.com/rancher/rke2/master/install.sh"
  files       = var.files
  assets      = { for a in data.github_release.selected.assets : a.name => a.browser_download_url }
}

data "github_release" "selected" {
  repository  = "rke2"
  owner       = "rancher"
  retrieve_by = "tag"
  release_tag = local.release
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
  file_permission      = "0644"
}

# requires curl to be installed in the environment running terraform
resource "null_resource" "download" {
  depends_on = [
    data.github_release.selected,
    local_file.download_dir,
  ]
  for_each = toset(local.files)
  provisioner "local-exec" {
    command = <<-EOT
      curl -L -s -o ${abspath("${path.root}/rke2/${each.key}")} ${lookup(local.assets, each.key, local.install_url)}
    EOT
  }
}
