locals {
  ssh_ip      = var.ssh_ip
  ssh_user    = var.ssh_user
  release     = var.release
  role        = var.role
  path        = var.path
  remote_path = "/home/${local.ssh_user}/rke2_artifacts"
  files       = var.files
  rke2_config = var.rke2_config
  identifier  = var.identifier
}

# don't use the local_file provider for the files
## we don't want to manage the files in case the user provided them and is managing them themselves

resource "null_resource" "copy_to_remote" {
  connection {
    type        = "ssh"
    user        = local.ssh_user
    script_path = "/home/${local.ssh_user}/rke2_copy_terraform"
    agent       = true
    host        = local.ssh_ip
  }
  provisioner "file" {
    source      = local.path
    destination = local.remote_path
  }
  triggers = {
    file_list   = join(",", local.files),
    release     = local.release,
    id          = local.identifier,
    rke2_config = sha256(local.rke2_config),
  }
}
resource "null_resource" "configure" {
  depends_on = [
    null_resource.copy_to_remote,
  ]
  connection {
    type        = "ssh"
    user        = local.ssh_user
    script_path = "/home/${local.ssh_user}/rke2_config_terraform"
    agent       = true
    host        = local.ssh_ip
  }
  # rke2-config contains either the content of the rke2_config variable or the rke2-config.yaml file (variable overrides file)
  # this provisioner will override the rke2-config.yaml file if it exists on the remote server
  provisioner "file" {
    content     = local.rke2_config
    destination = "${local.remote_path}/rke2-config.yaml"
  }
  provisioner "remote-exec" {
    inline = [<<-EOT
      set -x
      set -e
      sudo install -d /etc/rancher/rke2
      sudo cp ${local.remote_path}/rke2-config.yaml /etc/rancher/rke2/config.yaml
    EOT
    ]
  }
  triggers = {
    file_list   = join(",", local.files),
    release     = local.release,
    id          = local.identifier,
    rke2_config = sha256(local.rke2_config),
  }
}
resource "null_resource" "install" {
  depends_on = [
    null_resource.copy_to_remote,
    null_resource.configure,
  ]
  connection {
    type        = "ssh"
    user        = local.ssh_user
    script_path = "/home/${local.ssh_user}/rke2_install_terraform"
    agent       = true
    host        = local.ssh_ip
  }
  provisioner "remote-exec" {
    inline = [<<-EOT
      set -x
      set -e
      sudo chmod +x ${local.remote_path}/install.sh
      sudo INSTALL_RKE2_CHANNEL=${local.release} \
        INSTALL_RKE2_METHOD="tar" \
        INSTALL_RKE2_ARTIFACT_PATH="${local.remote_path}" \
        ${local.remote_path}/install.sh
    EOT
    ]
  }
  triggers = {
    file_list = join(",", local.files),
    release   = local.release,
    id        = local.identifier,
  }
}
resource "null_resource" "start" {
  depends_on = [
    null_resource.copy_to_remote,
    null_resource.configure,
    null_resource.install,
  ]
  connection {
    type        = "ssh"
    user        = local.ssh_user
    script_path = "/home/${local.ssh_user}/rke2_start_terraform"
    agent       = true
    host        = local.ssh_ip
  }
  provisioner "remote-exec" {
    inline = [<<-EOT
      set -x
      set -e
      if [ "$(sudo systemctl is-active rke2-${local.role}.service)" = "active" ]; then
        sudo systemctl stop rke2-${local.role}.service
      fi
      sudo systemctl daemon-reload
      sudo systemctl enable rke2-${local.role}.service
      sudo systemctl start rke2-${local.role}.service
    EOT
    ]
  }
  triggers = {
    file_list   = join(",", local.files),
    release     = local.release,
    id          = local.identifier,
    rke2_config = sha256(local.rke2_config),
  }
}
