locals {
  email          = "you@example.com"
  name           = "rke2-basic"
  username       = "you"
  public_ssh_key = "ssh-type your+public+ssh+key+here you@example.com"
}

# in this example we are generating new VPC, subnet, security group, and ssh key pair objects in AWS
## you probably want to select existing resources in your own environment
## the aws_access module can accomplish this for you, just pass in the names of the resources you want to use
## to be found, resources must be tagged with the key "Name" and the value you pass in
module "aws_access" {
  source              = "github.com/rancher/terraform-aws-access"
  owner               = local.email
  vpc_name            = local.name
  vpc_cidr            = "10.0.0.0/16"
  subnet_name         = local.name
  subnet_cidr         = "10.0.1.0/24"
  security_group_name = local.name
  security_group_type = "egress"
  ssh_key_name        = local.username
  public_ssh_key      = local.public_ssh_key
}

module "aws_server" {
  depends_on                 = [module.aws_access]
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

module "TestByob" {
  depends_on = [
    module.aws_access,
    module.aws_server,
    module.config,
  ]
  source            = "../../"
  local_file_path   = "${path.module}/rke2"
  ssh_ip            = module.aws_server.public_ip
  ssh_user          = local.username
  rke2_config       = module.config.config
  server_identifier = module.aws_server.id
}
