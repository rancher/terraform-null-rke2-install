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
  username        = "tf-${local.identifier}"
  image           = "rhel-8-cis"
  vpc_cidr        = "10.1.0.0/16"
  subnet_cidr     = "10.1.253.0/24"
  ip              = chomp(data.http.myip.response_body)
  ssh_key         = var.key
  key_name        = var.key_name
  rke2_version    = var.rke2_version
  local_file_path = "${path.root}/data/${local.identifier}"
}

data "http" "myip" {
  url = "https://ipinfo.io/ip"
}

resource "random_pet" "server" {
  keepers = {
    # regenerate the pet name when the identifier changes
    identifier = local.identifier
  }
  length = 1
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "access" {
  source   = "rancher/access/aws"
  version  = "v2.1.2"
  vpc_name = "${local.project_name}-vpc"
  vpc_cidr = local.vpc_cidr
  subnets = {
    "${local.project_name}-sn" = {
      cidr              = local.subnet_cidr
      availability_zone = data.aws_availability_zones.available.names[0]
      public            = false # only provision private ips for this subnet
    }
  }
  security_group_name        = "${local.project_name}-sg"
  security_group_type        = "project"
  load_balancer_use_strategy = "skip"
}

module "server" {
  depends_on = [
    module.access,
  ]
  source                     = "rancher/server/aws"
  version                    = "v1.0.2"
  image_type                 = local.image
  server_name                = "${local.project_name}-${random_pet.server.id}"
  server_type                = "small"
  subnet_name                = module.access.subnets[keys(module.access.subnets)[0]].tags_all.Name
  security_group_name        = module.access.security_group.tags_all.Name
  direct_access_use_strategy = "ssh"  # either the subnet needs to be public or you must add an eip
  cloudinit_use_strategy     = "skip" # sle-micro-55 doesn't have cloudinit
  add_eip                    = true   # adding an eip to allow setup
  server_access_addresses = {         # you must include ssh access here to enable setup
    "runnerSsh" = {
      port     = 22
      protocol = "tcp"
      cidrs    = ["${local.ip}/32"]
    }
    "runnerKube" = {
      port     = 6443
      protocol = "tcp"
      cidrs    = ["${local.ip}/32"]
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

module "config" {
  source          = "rancher/rke2-config/local"
  version         = "v0.1.3"
  local_file_path = local.local_file_path
}


# everything before this module is not necessary, you can generate the resources manually or use other methods
module "this" {
  depends_on = [
    module.access,
    module.server,
    module.config,
  ]
  source = "../../" # change this to "rancher/rke2-install/null" per https://registry.terraform.io/modules/rancher/rke2-install/null/latest
  # version = "v0.2.7" # when using this example you will need to set the version
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
