locals {
  email          = "terraform-ci@suse.com"
  identifier     = var.identifier
  name           = "tf-rke2-install-remote-${local.identifier}"
  username       = "tf-${local.identifier}"
  local_path     = "./rke2"
  remote_path    = "/home/${local.username}/rke2"
  rke2_version   = var.rke2_version # I want ci to be able to get the latest version of rke2 to test
  public_ssh_key = var.key          # I don't normally recommend using variables in root modules, but it allows tests to supply their own key
  key_name       = var.key_name     # A lot of troubleshooting during critical times can be saved by hard coding variables in root modules
  # root modules should be secured properly (including the state), and should represent your running infrastructure
}

# selecting the vpc, subnet, and ssh key pair, generating a security group specific to the ci runner
module "aws_access" {
  source              = "rancher/access/aws"
  version             = "v0.0.8"
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
  version             = "v0.0.16"
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

# the default location for the files will be `./rke2`
module "download" {
  source  = "rancher/rke2-download/github"
  version = "v0.0.1"
}

# an example of how to get the files to the remote server outside of using this module
# this resouce allows us to test the module as if the files were already on the remote server
resource "null_resource" "copy_to_remote" {
  depends_on = [
    module.aws_access,
    module.aws_server,
    module.download,
  ]
  connection {
    type        = "ssh"
    user        = local.username
    script_path = "/home/${local.username}/tf_ex_copy_to_remote"
    agent       = true
    host        = module.aws_server.public_ip
  }
  provisioner "file" {
    source      = local.local_path
    destination = local.remote_path
  }
  provisioner "remote-exec" {
    inline = [<<-EOT
      set -x
      set -e
      ls -lah ${local.remote_path}
    EOT
    ]
  }
}

module "TestRemote" {
  depends_on = [
    module.aws_access,
    module.aws_server,
    module.download,
    null_resource.copy_to_remote,
  ]
  source = "../../" # change this to "rancher/rke2-install/null" per https://registry.terraform.io/modules/rancher/rke2-install/null/latest
  # version = "v0.0.21" # when using this example you will need to set the version
  ssh_ip           = module.aws_server.public_ip
  ssh_user         = local.username
  identifier       = module.aws_server.id
  release          = local.rke2_version
  remote_file_path = local.remote_path
}
