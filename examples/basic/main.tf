locals {
  email          = "terraform-ci@suse.com"
  name           = "test-install"
  username       = "terraform-ci"
  public_ssh_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ4HmZ/KHZ/8KsvYlz6wqpoWoOaH1edHId2aK6niqKIw terraform-ci@suse.com"
}

# selecting the vpc, subnet, and ssh key pair, generating a security group specific to the ci runner
module "aws_access" {
  source              = "github.com/rancher/terraform-aws-access"
  owner               = local.email
  vpc_name            = "default"
  subnet_name         = "default"
  security_group_name = local.username
  security_group_type = "specific"
  ssh_key_name        = local.username
}

module "aws_server" {
  depends_on                 = [module.aws_access]
  source                     = "github.com/rancher/terraform-aws-server"
  image                      = "sles-15"
  server_owner               = local.email
  server_name                = local.name
  server_type                = "medium"
  server_user                = local.username
  server_ssh_key             = local.public_ssh_key
  server_subnet_name         = "default"
  server_security_group_name = module.aws_access.security_group.name
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
  release           = "v1.27.3+rke2r1"
}
