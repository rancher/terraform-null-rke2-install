locals {
  release         = var.release
  arch            = var.arch
  system          = var.system
  ssh_ip          = var.ssh_ip
  ssh_user        = var.ssh_user
  rke2_config     = var.rke2_config
  local_file_path = var.local_file_path
  file_path       = (local.local_file_path == "" ? "${path.root}/rke2" : local.local_file_path)
  expected_files = toset([
    "rke2-images.${local.system}-${local.arch}.tar.gz",
    "rke2.${local.system}-${local.arch}.tar.gz",
    "sha256sum-${local.arch}.txt",
    "rke2-install",
    "rke2-config.yaml",
  ])
  server_identifier = var.server_identifier
}

module "download" {
  # skip download if local_file_path is set
  count   = (local.local_file_path == "" ? 1 : 0)
  source  = "./modules/download"
  release = local.release
  arch    = local.arch
  system  = local.system
}

resource "local_file" "rke2_config" {
  count                = (local.rke2_config == "" ? 0 : 1)
  content              = local.rke2_config
  filename             = "${local.file_path}/rke2-config.yaml"
  directory_permission = "0755"
  file_permission      = "0755"
}

module "install" {
  depends_on     = [module.download]
  source         = "./modules/install"
  release        = local.release
  arch           = local.arch
  system         = local.system
  ssh_ip         = local.ssh_ip
  ssh_user       = local.ssh_user
  path           = local.file_path
  expected_files = local.expected_files
  identifier     = local.server_identifier
}
