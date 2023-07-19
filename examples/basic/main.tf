locals {
  email          = "you@example.com"
  name           = "rke2-basic"
  username       = "you"
  public_ssh_key = "ssh-type your+public+ssh+key+here you@example.com"
}

module "aws_access" {
  source              = "github.com/rancher/terraform-aws-access"
  owner               = local.email
  vpc_name            = local.name
  vpc_cidr            = "10.0.0.0/16"
  subnet_name         = local.name
  subnet_cidr         = "10.0.1.0/24"
  security_group_name = local.name
  security_group_type = "egress"
  ssh_key_name        = local.email
  public_ssh_key      = local.public_ssh_key
}

module "aws_server" {
  source                     = "github.com/rancher/terraform-aws-server"
  image                      = "sles-15"
  server_owner               = local.email
  server_name                = local.name
  server_type                = "small"
  server_user                = local.username
  server_ssh_key             = local.public_ssh_key
  server_subnet_name         = local.name
  server_security_group_name = local.name
}

module "config" {
  source = "github.com/rancher/terraform-local-rke2-config"
}

module "TestBasic" {
  depends_on = [
    module.aws_access,
    module.aws_server,
    module.config,
  ]
  source   = "../../"
  ssh_ip   = module.aws_server.public_ip
  ssh_user = local.username
}
