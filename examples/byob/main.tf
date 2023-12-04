
provider "aws" {
  default_tags {
    tags = {
      ID = local.identifier
    }
  }
}

locals {
  email          = "terraform-ci@suse.com"
  identifier     = var.identifier
  name           = "tf-install-byob-${local.identifier}"
  username       = "tf-${local.identifier}"
  rke2_version   = var.rke2_version
  public_ssh_key = var.key
  key_name       = var.key_name
  config = ( can(file("${path.root}/rke2/rke2-config.yaml")) ? file("${path.root}/rke2/rke2-config.yaml") : "")
}

module "aws_access" {
  source              = "rancher/access/aws"
  version             = "v0.1.1"
  owner               = local.email
  vpc_name            = "default"
  subnet_name         = "default"
  security_group_name = local.name
  security_group_type = "specific" # https://github.com/rancher/terraform-aws-access/blob/main/modules/security_group/types.tf
  ssh_key_name        = local.key_name
}

module "aws_server" {
  depends_on          = [module.aws_access]
  source              = "rancher/server/aws"
  version             = "v0.1.0"
  image               = "sles-15" # https://github.com/rancher/terraform-aws-server/blob/main/modules/image/types.tf
  owner               = local.email
  name                = local.name
  type                = "medium" # https://github.com/rancher/terraform-aws-server/blob/main/modules/server/types.tf
  user                = local.username
  ssh_key             = local.public_ssh_key
  ssh_key_name        = local.key_name
  subnet_name         = "default"
  security_group_name = module.aws_access.security_group_name
}

module "TestByob" {
  depends_on = [
    module.aws_access,
    module.aws_server,
  ]
  source = "../../" # change this to "rancher/rke2-install/null" per https://registry.terraform.io/modules/rancher/rke2-install/null/latest
  # version = "v0.2.7" # when using this example you will need to set the version
  local_file_path = "${abspath(path.root)}/rke2"
  ssh_ip          = module.aws_server.public_ip
  ssh_user        = local.username
  release         = local.rke2_version
  identifier      = md5(join("-",[
    # if any of these things change, redeploy rke2
    module.aws_server.id,
    local.rke2_version,
    local.config,
  ]))
}
