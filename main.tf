locals {
  release         = var.release
  type            = var.type
  local_file_path = var.local_file_path
}


module "download" {
  # skip download if local_file_path is set
  count   = (local.local_file_path == "" ? 1 : 0)
  source  = "./modules/download"
  release = local.release
  type    = local.type
}

module "install" {
  source = "./modules/install"
}

module "join" {
  source = "./modules/join"
}
