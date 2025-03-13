provider "aws" {
  default_tags {
    tags = {
      Id    = local.identifier
      Owner = local.email
    }
  }
}

# test install on rhel-9 (prep script with workarounds)
locals {
  identifier      = var.identifier # this is a random unique string that can be used to identify resources in the cloud provider
  email           = "terraform-ci@suse.com"
  example         = "candidate"
  project_name    = "tf-${substr(md5(join("-", [local.example, md5(local.identifier)])), 0, 5)}-${local.identifier}"
  username        = substr(lower("tf-${local.identifier}"), 0, 32)
  image           = "rhel-9"
  ip              = chomp(data.http.myip.response_body)
  ssh_key         = var.key
  rke2_version    = var.rke2_version
  rpm_channel     = var.rpm_channel
  local_file_path = "${path.root}/data/${local.identifier}"
}

data "http" "myip" {
  url = "https://ipinfo.io/ip"
  retry {
    attempts     = 2
    min_delay_ms = 1000
  }
}

resource "random_pet" "server" {
  keepers = {
    # regenerate the pet name when the identifier changes
    identifier = local.identifier
  }
  length = 1
}

module "access" {
  source                     = "rancher/access/aws"
  version                    = "v3.1.12"
  vpc_name                   = "${local.project_name}-vpc"
  vpc_public                 = true
  security_group_name        = "${local.project_name}-sg"
  security_group_type        = "project"
  load_balancer_use_strategy = "skip"
}

module "server" {
  depends_on = [
    module.access,
  ]
  source                     = "rancher/server/aws"
  version                    = "v1.4.0"
  image_type                 = local.image
  server_name                = "${local.project_name}-${random_pet.server.id}"
  server_type                = "small"
  subnet_name                = keys(module.access.subnets)[0]
  security_group_name        = module.access.security_group.tags_all.Name
  direct_access_use_strategy = "ssh"     # either the subnet needs to be public or you must add an eip
  cloudinit_use_strategy     = "default" # use the default cloudinit config
  server_access_addresses = {            # you must include ssh access here to enable setup
    "runner" = {
      port      = 22
      protocol  = "tcp"
      cidrs     = ["${local.ip}/32"]
      ip_family = "ipv4"
    }
  }
  server_user = {
    user                     = local.username
    aws_keypair_use_strategy = "skip"        # we will use cloud-init to add a keypair directly
    ssh_key_name             = ""            # not creating or selecting a key, but this field is still required
    public_ssh_key           = local.ssh_key # ssh key to add via cloud-init
    user_workfolder          = "/home/${local.username}"
    timeout                  = 5
  }
}

module "config" {
  source          = "rancher/rke2-config/local"
  version         = "v1.0.0"
  local_file_path = local.local_file_path
}


# everything before this module is not necessary, you can generate the resources manually or use other methods
module "this" {
  depends_on = [
    module.access,
    module.server,
    module.config,
  ]
  source              = "../../" # dev/test only source, for proper source see https://registry.terraform.io/modules/rancher/rke2-install/null/latest
  ssh_ip              = module.server.server.public_ip
  ssh_user            = local.username
  release             = local.rke2_version
  rpm_channel         = local.rpm_channel
  local_file_path     = local.local_file_path
  retrieve_kubeconfig = true
  install_method      = "rpm"
  remote_workspace    = module.server.image.workfolder
  server_prep_script  = file("${path.root}/prep.sh")
  identifier = md5(join("-", [
    # if any of these things change, redeploy rke2
    module.server.server.id,
    local.rke2_version,
    module.config.yaml_config,
  ]))
}
