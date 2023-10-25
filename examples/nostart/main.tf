locals {
  email          = "terraform-ci@suse.com"
  identifier     = var.identifier
  name           = "tf-rke2-${local.identifier}"
  username       = "tf-${local.identifier}"
  file_path      = "tf-${local.identifier}"
  extra_config   = file("${abspath(path.root)}/config.yaml")
  prep_script    = file("${abspath(path.root)}/prep.sh")
  rke2_version   = var.rke2_version # I want ci to be able to get the latest version of rke2 to test
  public_ssh_key = var.key          # I don't normally recommend using variables in root modules, but it allows tests to supply their own key
  key_name       = var.key_name     # A lot of troubleshooting during critical times can be saved by hard coding variables in root modules
  # root modules should be secured properly (including the state), and should represent your running infrastructure
}
resource "random_uuid" "join_token" {}

# selecting the vpc, subnet, and ssh key pair, generating a security group specific to the ci runner
module "aws_access" {
  source              = "rancher/access/aws"
  version             = "v0.0.8"
  owner               = local.email
  vpc_name            = "default"
  subnet_name         = "default"
  security_group_name = local.name
  security_group_type = "egress" # https://github.com/rancher/terraform-aws-access/blob/main/modules/security_group/types.tf
  ssh_key_name        = local.key_name
}

module "aws_server" {
  depends_on = [
    module.aws_access
  ]
  source              = "rancher/server/aws"
  version             = "v0.0.16"
  image               = "rhel-8-cis" # https://github.com/rancher/terraform-aws-server/blob/main/modules/image/types.tf
  owner               = local.email
  name                = local.name
  type                = "small" # https://github.com/rancher/terraform-aws-server/blob/main/modules/server/types.tf
  user                = local.username
  ssh_key             = local.public_ssh_key
  ssh_key_name        = local.key_name
  subnet_name         = "default"
  security_group_name = module.aws_access.security_group_name
}

module "config" {
  depends_on = [
    module.aws_access,
    module.aws_server,
  ]
  source            = "rancher/rke2-config/local"
  version           = "v0.1.0"
  token             = random_uuid.join_token.result
  advertise-address = module.aws_server.private_ip
  tls-san           = [module.aws_server.public_ip, module.aws_server.private_ip]
  node-external-ip  = [module.aws_server.public_ip]
  node-ip           = [module.aws_server.private_ip]
}

resource "null_resource" "write_config" {
  depends_on = [
    module.aws_access,
    module.aws_server,
    module.config,
  ]
  for_each = toset(["${local.file_path}/50-initial-generated-config.yaml"])
  triggers = {
    config_content = module.config.yaml_config,
  }
  provisioner "local-exec" {
    command = <<-EOT
      set -e
      set -x
      install -d "${local.file_path}"
      cat << 'EOF' > "${each.key}"
      ${module.config.yaml_config}
      EOF
      chmod 0600 "${each.key}"
    EOT
  }
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      rm -f "${each.key}"
    EOT
  }
}

resource "null_resource" "write_extra_config" {
  depends_on = [
    module.aws_access,
    module.aws_server,
    module.config,
  ]
  for_each = toset(["${local.file_path}/51-extra-config.yaml"])
  triggers = {
    config_content = local.extra_config,
  }
  provisioner "local-exec" {
    command = <<-EOT
      set -e
      set -x
      install -d "${local.file_path}"
      cat << 'EOF' > "${each.key}"
      ${local.extra_config}
      EOF
      chmod 0600 "${each.key}"
    EOT
  }
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      rm -f "${each.key}"
    EOT
  }
}

# everything before this module is not necessary, you can generate the resources manually or using other methods
module "install_without_starting" {
  depends_on = [
    module.aws_access,
    module.aws_server,
    module.config,
    null_resource.write_config,
    null_resource.write_extra_config,
  ]
  source = "../../" # change this to "rancher/rke2-install/null" per https://registry.terraform.io/modules/rancher/rke2-install/null/latest
  # version = "v0.1.1" # when using this example you will need to set the version
  ssh_ip             = module.aws_server.public_ip
  ssh_user           = local.username
  identifier         = module.aws_server.id
  release            = local.rke2_version
  install_method     = "rpm"
  local_file_path    = local.file_path
  remote_workspace   = module.aws_server.workfolder
  server_prep_script = local.prep_script
  start              = false
}
