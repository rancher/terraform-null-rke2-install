locals {
  ssh_ip      = var.ssh_ip
  ssh_user    = var.ssh_user
  release     = var.release
  system      = var.system
  arch        = var.arch
  files       = var.expected_files
  local_path  = var.path
  remote_path = "/home/${local.ssh_user}/rke2_artifacts"
}
resource "local_sensitive_file" "install" {
  for_each             = toset([for file in local.files : file if fileexists("${local.local_path}/${file}")])
  source               = "${local.local_path}/${each.key}"
  filename             = "${local.local_path}/${each.key}"
  file_permission      = "0755"
  directory_permission = "0755"
}
resource "null_resource" "copy_to_remote" {
  depends_on = [local_sensitive_file.install]
  connection {
    type        = "ssh"
    user        = local.ssh_user
    script_path = "/home/${local.ssh_user}/rke2_copy_terraform"
    agent       = true
    host        = local.ssh_ip
  }
  provisioner "file" {
    source      = local.local_path
    destination = local.remote_path
  }
  triggers = {
    files = md5(jsonencode(local_sensitive_file.install[*])),
    ip    = local.ssh_ip, # assumes that if the IP changes, we are dealing with a new host
  }
}
resource "null_resource" "configure" {
  depends_on = [
    local_sensitive_file.install,
    null_resource.copy_to_remote,
  ]
  connection {
    type        = "ssh"
    user        = local.ssh_user
    script_path = "/home/${local.ssh_user}/rke2_config_terraform"
    agent       = true
    host        = local.ssh_ip
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
    files = md5(jsonencode(local_sensitive_file.install[*])),
    ip    = local.ssh_ip, # assumes that if the IP changes, we are dealing with a new host
  }
}
resource "null_resource" "install" {
  depends_on = [
    local_sensitive_file.install,
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
      sudo chmod +x ${local.remote_path}/rke2-install
      sudo INSTALL_RKE2_CHANNEL=${local.release} \
        INSTALL_RKE2_METHOD="tar" \
        INSTALL_RKE2_ARTIFACT_PATH="${local.remote_path}" \
        ${local.remote_path}/rke2-install
    EOT
    ]
  }
  triggers = {
    files = md5(jsonencode(local_sensitive_file.install[*])),
    ip    = local.ssh_ip, # assumes that if the IP changes, we are dealing with a new host
  }
}
resource "null_resource" "start" {
  depends_on = [
    local_sensitive_file.install,
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
      sudo systemctl enable rke2-server.service
      sudo systemctl start rke2-server.service
    EOT
    ]
  }
  triggers = {
    files = md5(jsonencode(local_sensitive_file.install[*])),
    ip    = local.ssh_ip, # assumes that if the IP changes, we are dealing with a new host
  }
}