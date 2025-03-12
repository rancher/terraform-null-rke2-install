
provider "aws" {
  default_tags {
    tags = {
      ID    = local.identifier
      Owner = local.email
    }
  }
}

locals {
  email        = "terraform-ci@suse.com"
  identifier   = var.identifier
  example      = "byob"
  project_name = "tf-${substr(md5(join("-", [local.example, md5(local.identifier)])), 0, 5)}-${local.identifier}"
  username     = substr(lower("tf-${local.identifier}"), 0, 32)
  rke2_version = var.rke2_version
  image        = "sles-15"
  ip           = chomp(data.http.myip.response_body)
  ssh_key      = var.key
  config       = (can(file("${path.root}/rke2/rke2-config.yaml")) ? file("${path.root}/rke2/rke2-config.yaml") : "")
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

module "this" {
  depends_on = [
    module.access,
    module.server,
  ]
  source          = "../../" # dev/test only source, for proper source see https://registry.terraform.io/modules/rancher/rke2-install/null/latest
  local_file_path = "${abspath(path.root)}/rke2"
  ssh_ip          = module.server.server.public_ip
  ssh_user        = local.username
  release         = local.rke2_version
  identifier = md5(join("-", [
    # if any of these things change, redeploy rke2
    module.server.server.id,
    local.rke2_version,
    local.config,
  ]))
  start_timeout = 10
}
