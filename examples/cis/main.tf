provider "aws" {
  default_tags {
    tags = {
      Id    = local.identifier
      Owner = local.email
    }
  }
}

# test install on rhel-8 cis STIG image, (no home execute, non-standard install directory)
locals {
  identifier      = var.identifier # this is a random unique string that can be used to identify resources in the cloud provider
  email           = "terraform-ci@suse.com"
  example         = "cis"
  project_name    = "tf-${substr(md5(join("-", [local.example, md5(local.identifier)])), 0, 5)}-${local.identifier}"
  username        = substr(lower("tf-${local.identifier}"), 0, 31)
  image           = "cis-rhel-8"
  ip              = chomp(data.http.myip.response_body)
  ssh_key         = var.key
  key_name        = var.key_name
  rke2_version    = var.rke2_version
  local_file_path = "${path.root}/data/${local.identifier}"
  zone            = var.zone
}

data "http" "myip" {
  url = "https://ipinfo.io/ip"
  retry {
    attempts     = 2
    min_delay_ms = 1000
  }
}

module "access" {
  source                     = "rancher/access/aws"
  version                    = "v3.1.12"
  vpc_name                   = "${local.project_name}-vpc"
  vpc_public                 = false
  security_group_name        = "${local.project_name}-sg"
  security_group_type        = "egress"
  load_balancer_use_strategy = "skip"
  domain                     = local.project_name
  domain_zone                = local.zone
}

module "server" {
  depends_on = [
    module.access,
  ]
  source                     = "rancher/server/aws"
  version                    = "v1.4.0"
  image_type                 = local.image
  server_name                = local.project_name
  server_type                = "medium"
  subnet_name                = keys(module.access.subnets)[0]
  security_group_name        = module.access.security_group.tags_all.Name
  direct_access_use_strategy = "ssh"  # either the subnet needs to be public or you must add an eip
  cloudinit_use_strategy     = "skip" # sle-micro-55 doesn't have cloudinit
  add_eip                    = true   # adding an eip to allow setup
  server_access_addresses = {         # you must include ssh access here to enable setup
    "runnerSsh" = {
      port      = 22
      protocol  = "tcp"
      cidrs     = ["${local.ip}/32"]
      ip_family = "ipv4"
    }
    "runnerKube" = {
      port      = 6443
      protocol  = "tcp"
      cidrs     = ["${local.ip}/32"]
      ip_family = "ipv4"
    }
  }
  server_user = {
    user                     = local.username
    aws_keypair_use_strategy = "select"
    ssh_key_name             = local.key_name
    public_ssh_key           = local.ssh_key # ssh key to add via cloud-init
    user_workfolder          = "/var/tmp"
    timeout                  = 5
  }
}

# the idea here is to provide the least amount of config necessary to get a cluster up and running
module "config" {
  depends_on = [
    module.access,
    module.server,
  ]
  source  = "rancher/rke2-config/local"
  version = "v1.0.0"
  tls-san = distinct(compact([
    lower("${local.project_name}.${local.zone}"),
  ]))
  node-external-ip  = [module.server.server.public_ip]
  node-ip           = [module.server.server.private_ip]
  node-name         = local.project_name
  advertise-address = module.server.server.private_ip
  local_file_path   = local.local_file_path
}

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
  local_file_path     = local.local_file_path
  retrieve_kubeconfig = true
  install_method      = "rpm"
  remote_workspace    = module.server.image.workfolder
  server_prep_script  = file("${path.root}/prep.sh")
  start_timeout       = 10
  identifier = md5(join("-", [
    # if any of these things change, redeploy rke2
    module.server.server.id,
    local.rke2_version,
    module.config.yaml_config,
  ]))
}
