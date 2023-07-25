locals {
  release             = var.release
  arch                = var.arch
  system              = var.system
  role                = var.role
  ssh_ip              = var.ssh_ip
  ssh_user            = var.ssh_user
  server_identifier   = var.server_identifier
  local_file_path     = var.local_file_path
  file_path           = (local.local_file_path == "" ? "${path.root}/rke2" : local.local_file_path)
  config_content      = var.rke2_config
  config_file_content = (can(file("${local.file_path}/rke2-config.yaml")) ? file("${local.file_path}/rke2-config.yaml") : "")
  rke2_config         = (local.config_content == "" ? local.config_file_content : local.config_content)

  # if these files don't exist in the file_path, the install module will fail
  expected_files = toset([
    "rke2-images.${local.system}-${local.arch}.tar.gz",
    "rke2.${local.system}-${local.arch}.tar.gz",
    "sha256sum-${local.arch}.txt",
    "install.sh",
    "rke2-config.yaml",
  ])
}

module "download" {
  # skip download if local_file_path is set
  count   = (local.local_file_path == "" ? 1 : 0)
  source  = "./modules/download"
  release = local.release
  files   = setsubtract(local.expected_files, toset(["rke2-config.yaml"]))
}

module "install" {
  depends_on  = [module.download]
  source      = "./modules/install"
  release     = local.release
  role        = local.role
  ssh_ip      = local.ssh_ip
  ssh_user    = local.ssh_user
  rke2_config = local.rke2_config
  path        = local.file_path
  identifier  = local.server_identifier
  files       = local.expected_files
}
