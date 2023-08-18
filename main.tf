locals {
  release           = var.release
  arch              = var.arch
  system            = var.system
  role              = var.role
  ssh_ip            = var.ssh_ip
  ssh_user          = var.ssh_user
  server_identifier = var.server_identifier
  local_file_path   = var.local_file_path
  file_path         = (local.local_file_path == "" ? "${path.root}/rke2" : local.local_file_path)
  config_content    = var.rke2_config

  # if these files don't exist in the file_path, the install will fail
  expected_files = toset([
    "rke2-images.${local.system}-${local.arch}.tar.gz",
    "rke2.${local.system}-${local.arch}.tar.gz",
    "sha256sum-${local.arch}.txt",
    "install.sh",
  ])
}

module "download" {
  # skip download if local_file_path is set
  count   = (local.local_file_path == "" ? 1 : 0)
  source  = "./modules/download"
  release = local.release
  files   = local.expected_files
}

resource "null_resource" "write_config" {
  # the name needs to be something highly unlikely to be used by a user, so that we don't clobber any of their configs
  # we also want the name to be easily recognizable for what it is (the initially generated config)
  # we also want the name to have an index so that users can supply their own configs before or after this one (they are merged alphabetically)
  for_each = toset(["${local.file_path}/50-initial_generate_config_puzzlingly.yaml"])
  triggers = {
    config_content = local.config_content,
  }
  provisioner "local-exec" {
    command = <<-EOT
      echo "${local.config_content}" > ${each.key}
    EOT
  }
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      rm -f  ${each.key}
    EOT
  }
}

module "install" {
  depends_on = [module.download]
  source     = "./modules/install"
  identifier = local.server_identifier
  release    = local.release
  role       = local.role
  ssh_ip     = local.ssh_ip
  ssh_user   = local.ssh_user
  path       = local.file_path
}
