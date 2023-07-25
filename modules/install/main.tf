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
      sudo cp ${local.remote_path}/rke2-config.yaml /etc/rancher/rke2/config.yaml || true
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
        TMP_DIR="/home/${local.ssh_user}/tmp-rke2-install" \
        ${local.remote_path}/install.sh
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
resource "null_resource" "reboot" {
  depends_on = [
    null_resource.copy_to_remote,
    null_resource.configure,
    null_resource.install,
    null_resource.start,
  ]
  connection {
    type        = "ssh"
    user        = local.ssh_user
    script_path = "/home/${local.ssh_user}/rke2_reboot_terraform"
    agent       = true
    host        = local.ssh_ip
  }
  provisioner "remote-exec" {
    inline = [<<-EOT
      set -x
      set -e
      sudo shutdown -r +1 &
      sudo systemctl stop sshd # stop sshd to prevent reconnect
      # the smallest amount of time shutdown will accept is 1 minute, 
      # so we sleep for 55 seconds to reduce the time to 5 seconds
      # that way we don't get false negatives on the next ssh connection
      sleep 55;
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
resource "null_resource" "validate" {
  depends_on = [
    null_resource.copy_to_remote,
    null_resource.configure,
    null_resource.install,
    null_resource.start,
    null_resource.reboot,
  ]
  connection {
    type        = "ssh"
    user        = local.ssh_user
    script_path = "/home/${local.ssh_user}/rke2_reboot_terraform"
    agent       = true
    host        = local.ssh_ip
  }
  provisioner "remote-exec" {
    inline = [<<-EOT
      set -x
      set -e
      max_attempts=15
      # this just validates that the server came back online and service is running
      while [ "$(systemctl is-active rke2-${local.role}.service)" != "active" ]; do
        sleep 10;
        max_attempts=$((max_attempts-1))
        if [ $max_attempts -eq 0 ]; then
          echo "rke2-${local.role}.service failed to start"
          exit 1
        fi
      done
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
