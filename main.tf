locals {
  release             = var.release
  channel             = var.rpm_channel
  role                = var.role
  ssh_ip              = var.ssh_ip
  ssh_user            = var.ssh_user
  identifier          = var.identifier
  local_file_path     = var.local_file_path
  local_path          = (local.local_file_path == "" ? "${abspath(path.root)}/rke2" : local.local_file_path)
  remote_workspace    = ((var.remote_workspace == "~" || var.remote_workspace == "") ? "/home/${local.ssh_user}" : var.remote_workspace) # https://github.com/hashicorp/terraform/issues/30243
  remote_path         = (var.remote_file_path == "" ? "${local.remote_workspace}/rke2_artifacts" : var.remote_file_path)
  retrieve_kubeconfig = var.retrieve_kubeconfig
  install_method      = var.install_method
  server_prep_script  = var.server_prep_script
  start               = var.start
  start_timeout       = var.start_timeout
}

# if local path specified copy all files and folders to the remote_path directory
resource "null_resource" "copy_to_remote" {
  triggers = {
    id = local.identifier,
  }
  connection {
    type        = "ssh"
    user        = local.ssh_user
    script_path = "${local.remote_workspace}/rke2_copy_terraform"
    agent       = true
    host        = local.ssh_ip
  }
  provisioner "file" {
    source      = local.local_path
    destination = local.remote_path
  }
  provisioner "remote-exec" {
    inline = [<<-EOT
      set -x
      set -e
      ls -lah "${local.remote_path}"
    EOT
    ]
  }
}
resource "null_resource" "configure" {
  depends_on = [
    null_resource.copy_to_remote,
  ]
  triggers = {
    id = local.identifier,
  }
  connection {
    type        = "ssh"
    user        = local.ssh_user
    script_path = "${local.remote_workspace}/rke2_config_terraform"
    agent       = true
    host        = local.ssh_ip
  }
  provisioner "file" {
    source      = "${abspath(path.module)}/configure.sh"
    destination = "${local.remote_workspace}/configure.sh"
  }
  provisioner "remote-exec" {
    inline = [<<-EOT
      set -x
      set -e
      sudo chmod +x ${local.remote_workspace}/configure.sh
      sudo ${local.remote_workspace}/configure.sh "${local.remote_path}"
    EOT
    ]
  }
}
# run the install script, which may upgrade rke2 if it is already installed
resource "null_resource" "install" {
  depends_on = [
    null_resource.copy_to_remote,
    null_resource.configure,
  ]
  triggers = {
    id = local.identifier,
  }
  connection {
    type        = "ssh"
    user        = local.ssh_user
    script_path = "${local.remote_workspace}/rke2_install_terraform"
    agent       = true
    host        = local.ssh_ip
  }
  provisioner "file" {
    source      = "${abspath(path.module)}/install.sh"
    destination = "${local.remote_workspace}/install.sh"
  }
  provisioner "remote-exec" {
    inline = [<<-EOT
      set -x
      set -e
      sudo chmod +x "${local.remote_workspace}/install.sh"
      sudo ${local.remote_workspace}/install.sh "${local.role}" "${local.remote_path}" "${local.release}" "${local.install_method}" "${local.channel}"
    EOT
    ]
  }
}
# optionally run a script on the server before starting rke2
# this can be used to mitigate OS specific issues or configuration
resource "null_resource" "prep" {
  count = (local.server_prep_script == "" ? 0 : 1)
  depends_on = [
    null_resource.copy_to_remote,
    null_resource.configure,
    null_resource.install,
  ]
  triggers = {
    id     = local.identifier,
    script = local.server_prep_script,
  }
  connection {
    type        = "ssh"
    user        = local.ssh_user
    script_path = "${local.remote_workspace}/rke2_server_prep_terraform"
    agent       = true
    host        = local.ssh_ip
  }
  provisioner "file" {
    content     = local.server_prep_script
    destination = "${local.remote_workspace}/prep.sh"
  }
  provisioner "remote-exec" {
    inline = [<<-EOT
      set -x
      set -e
      sudo chmod +x "${local.remote_workspace}/prep.sh"
      sudo ${local.remote_workspace}/prep.sh
    EOT
    ]
  }
}
# start or restart rke2 service
resource "null_resource" "start" {
  count = (local.start == true ? 1 : 0)
  depends_on = [
    null_resource.copy_to_remote,
    null_resource.configure,
    null_resource.install,
    null_resource.prep,
  ]
  triggers = {
    id = local.identifier,
  }
  connection {
    type        = "ssh"
    user        = local.ssh_user
    script_path = "${local.remote_workspace}/rke2_start_terraform"
    agent       = true
    host        = local.ssh_ip
  }
  provisioner "file" {
    source      = "${abspath(path.module)}/start.sh"
    destination = "${local.remote_workspace}/start.sh"
  }
  provisioner "remote-exec" {
    inline = [<<-EOT
      set -x
      set -e
      sudo chmod +x ${local.remote_workspace}/start.sh
      sudo ${local.remote_workspace}/start.sh "${local.role}" "${local.start_timeout}"
    EOT
    ]
  }
}
resource "null_resource" "get_kubeconfig" {
  count = (local.retrieve_kubeconfig == true ? 1 : 0)
  depends_on = [
    null_resource.copy_to_remote,
    null_resource.configure,
    null_resource.install,
    null_resource.start,
    null_resource.prep,
  ]
  triggers = {
    id = local.identifier,
  }
  connection {
    type        = "ssh"
    user        = local.ssh_user
    script_path = "${local.remote_workspace}/get_kubeconfig_terraform"
    agent       = true
    host        = local.ssh_ip
  }
  provisioner "remote-exec" {
    inline = [<<-EOT
      set -x
      set -e
      sudo cp /etc/rancher/rke2/rke2.yaml "${local.remote_workspace}/kubeconfig.yaml"
      sudo chown ${local.ssh_user} "${local.remote_workspace}/kubeconfig.yaml"
    EOT
    ]
  }
  provisioner "local-exec" {
    command = <<-EOT
      set -x
      set -e
      FILE="${local.local_path}/kubeconfig-${local.identifier}.yaml"
      REMOTE_PATH="${local.remote_workspace}/kubeconfig.yaml"
      IP="${local.ssh_ip}"
      SSH_USER="${local.ssh_user}"

      chmod +x "${abspath(path.module)}/get_kubeconfig.sh"
      "${abspath(path.module)}/get_kubeconfig.sh" "$FILE" "$REMOTE_PATH" "$IP" "$SSH_USER"
    EOT
  }
}
data "local_file" "kubeconfig" {
  count = (local.retrieve_kubeconfig == true ? 1 : 0)
  depends_on = [
    null_resource.copy_to_remote,
    null_resource.configure,
    null_resource.install,
    null_resource.start,
    null_resource.get_kubeconfig,
    null_resource.prep,
  ]
  filename = "${local.local_path}/kubeconfig-${local.identifier}.yaml"
}
