locals {
  email          = "terraform-ci@suse.com"
  name           = "test-tf-mod-rke2-install"
  username       = "terraform-ci"
  public_ssh_key = var.key      # I don't normally recommend using variables in root modules, but it allows tests to supply their own key
  key_name       = var.key_name # A lot of troubleshooting during critical times can be saved by hard coding variables in root modules
  release        = var.release  # root modules should be secured properly (including the state), and should represent your running infrastructure
}

# selecting the vpc, subnet, and ssh key pair, generating a security group specific to the ci runner
module "aws_access" {
  source              = "github.com/rancher/terraform-aws-access"
  owner               = local.email
  vpc_name            = "default"
  subnet_name         = "default"
  security_group_name = local.username
  security_group_type = "specific"
  ssh_key_name        = local.key_name
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

module "TestByob" {
  depends_on = [
    module.aws_access,
    module.aws_server,
  ]
  source            = "../../"
  local_file_path   = "${abspath(path.root)}/rke2"
  ssh_ip            = module.aws_server.public_ip
  ssh_user          = local.username
  server_identifier = module.aws_server.id
  release           = local.release
}
