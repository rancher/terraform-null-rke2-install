locals {
  email          = "terraform-ci@suse.com"
  name           = "terraform-rke2-install"
  username       = "terraform-ci"
  rke2_version   = var.rke2_version # I want ci to be able to get the latest version of rke2 to test
  public_ssh_key = var.key          # I don't normally recommend using variables in root modules, but it allows tests to supply their own key
  key_name       = var.key_name     # A lot of troubleshooting during critical times can be saved by hard coding variables in root modules
  # root modules should be secured properly (including the state), and should represent your running infrastructure
}

# selecting the vpc, subnet, and ssh key pair, generating a security group specific to the ci runner
module "aws_access" {
  source              = "rancher/access/aws"
  version             = "v0.0.5"
  owner               = local.email
  vpc_name            = "default"
  subnet_name         = "default"
  security_group_name = local.name
  security_group_type = "specific"
  ssh_key_name        = local.key_name
}

module "aws_server" {
  depends_on                 = [module.aws_access]
  source                     = "rancher/server/aws"
  version                    = "v0.0.11"
  image                      = "sles-15"
  server_owner               = local.email
  server_name                = local.name
  server_type                = "medium"
  server_user                = local.username
  server_ssh_key             = local.public_ssh_key
  server_subnet_name         = "default"
  server_security_group_name = module.aws_access.security_group_name
}

module "config" {
  source = "github.com/rancher/terraform-local-rke2-config"
}

# everything before this module is not necessary, you can generate the resources manually or using other methods
module "TestBasic" {
  depends_on = [
    module.aws_access,
    module.aws_server,
    module.config,
  ]
  source            = "../../"
  ssh_ip            = module.aws_server.public_ip
  ssh_user          = local.username
  rke2_config       = module.config.yaml_config
  server_identifier = module.aws_server.id
  release           = local.rke2_version
}
