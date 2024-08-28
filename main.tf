locals {
  release = var.release
  channel = var.rpm_channel
  role    = var.role
  ssh_ip  = var.ssh_ip
  # tflint-ignore: terraform_unused_declarations
  ssh_ip_fail                = (local.ssh_ip == "" ? one([local.ssh_ip, "missing_ip"]) : false)
  ssh_user                   = var.ssh_user
  identifier                 = var.identifier
  local_file_path            = var.local_file_path
  local_path                 = (local.local_file_path == "" ? "${abspath(path.root)}/rke2" : local.local_file_path)
  local_manifests_path       = var.local_manifests_path
  remote_workspace           = ((var.remote_workspace == "~" || var.remote_workspace == "") ? "/home/${local.ssh_user}" : var.remote_workspace) # https://github.com/hashicorp/terraform/issues/30243
  remote_path                = (var.remote_file_path == "" ? "${local.remote_workspace}/rke2_artifacts" : var.remote_file_path)
  retrieve_kubeconfig        = var.retrieve_kubeconfig
  install_method             = var.install_method
  server_prep_script         = var.server_prep_script
  server_install_prep_script = var.server_install_prep_script
  start                      = var.start
  start_timeout              = var.start_timeout
}

# if local path specified copy all files and folders to the remote_path directory
resource "terraform_data" "copy_to_remote" {
  triggers_replace = local.identifier
  connection {
    type        = "ssh"
    user        = local.ssh_user
    script_path = "${local.remote_workspace}/rke2_copy_terraform"
    agent       = true
    host        = local.ssh_ip
  }
  provisioner "remote-exec" {
    inline = [<<-EOT
      echo "Connected!"
    EOT
    ]
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
    terraform_data.copy_to_remote,
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
  provisioner "remote-exec" {
    inline = [<<-EOT
      echo "Connected!"
    EOT
    ]
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

# optionally run a script on the server before starting rke2
# this can be used to mitigate OS specific issues or configuration
# skipped when using the tarball install method because it should be self contained
resource "null_resource" "install_prep" {
  count = (local.server_install_prep_script == "" ? 0 : 1)
  depends_on = [
    terraform_data.copy_to_remote,
    null_resource.configure,
  ]
  triggers = {
    id     = local.identifier,
    script = md5(local.server_install_prep_script),
  }
  connection {
    type        = "ssh"
    user        = local.ssh_user
    script_path = "${local.remote_workspace}/rke2_server_install_prep_terraform"
    agent       = true
    host        = local.ssh_ip
  }
  provisioner "remote-exec" {
    inline = [<<-EOT
      echo "Connected!"
    EOT
    ]
  }
  provisioner "file" {
    content     = local.server_install_prep_script
    destination = "${local.remote_workspace}/install_prep.sh"
  }
  provisioner "remote-exec" {
    inline = [<<-EOT
      set -x
      set -e
      sudo chmod +x "${local.remote_workspace}/install_prep.sh"
      sudo ${local.remote_workspace}/install_prep.sh
    EOT
    ]
  }
  provisioner "remote-exec" {
    inline = [<<-EOT
      echo "rebooting..."
      sudo reboot
    EOT
    ]
    on_failure = continue
  }
}
resource "time_sleep" "ten_s_before_install" {
  depends_on = [
    terraform_data.copy_to_remote,
    null_resource.configure,
    null_resource.install_prep,
  ]
  create_duration = "10s"
}
# run the install script, which may upgrade rke2 if it is already installed
resource "null_resource" "install" {
  depends_on = [
    terraform_data.copy_to_remote,
    null_resource.configure,
    null_resource.install_prep,
    time_sleep.ten_s_before_install,
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
  provisioner "remote-exec" {
    inline = [<<-EOT
      echo "Connected!"
    EOT
    ]
  }
  provisioner "file" {
    source      = "${abspath(path.module)}/install.sh"
    destination = "${local.remote_workspace}/install.sh"
  }
  provisioner "remote-exec" {
    inline = [<<-EOT
      set -x
      set -e
      echo "Uptime is "$(sudo uptime | awk '{print $3}' | awk -F: '{print $2}' | awk -F, '{print $1}') min", it should be low."
      sudo chmod +x "${local.remote_workspace}/install.sh"
      sudo ${local.remote_workspace}/install.sh "${local.role}" "${local.remote_path}" "${local.release}" "${local.install_method}" "${local.channel}"
    EOT
    ]
  }
  provisioner "remote-exec" {
    inline = [<<-EOT
      sudo reboot
    EOT
    ]
    on_failure = continue
  }
}
resource "time_sleep" "ten_s_after_install" {
  depends_on = [
    terraform_data.copy_to_remote,
    null_resource.configure,
    null_resource.install_prep,
    time_sleep.ten_s_before_install,
    null_resource.install,
  ]
  create_duration = "10s"
}

# copy manifests to remote server after install, but before start
resource "terraform_data" "copy_manifests" {
  count = (local.local_manifests_path == "" ? 0 : 1)
  depends_on = [
    terraform_data.copy_to_remote,
    null_resource.configure,
    null_resource.install_prep,
    time_sleep.ten_s_before_install,
    null_resource.install,
    time_sleep.ten_s_after_install,
  ]
  triggers_replace = local.identifier
  connection {
    type        = "ssh"
    user        = local.ssh_user
    script_path = "${local.remote_workspace}/copy_manifests_terraform"
    agent       = true
    host        = local.ssh_ip
  }
  provisioner "remote-exec" {
    inline = [<<-EOT
      echo "Connected!"
    EOT
    ]
  }
  provisioner "file" {
    source      = local.local_manifests_path
    destination = "${local.remote_path}/manifests"
  }
  provisioner "remote-exec" {
    inline = [<<-EOT
      set -x
      set -e
      ls -lah ${local.remote_path}/manifests
      sudo install -d /var/lib/rancher/rke2/server/manifests
      sudo cp ${local.remote_path}/manifests/* /var/lib/rancher/rke2/server/manifests
      ls -lah /var/lib/rancher/rke2/server/manifests
    EOT
    ]
  }
}

# optionally run a script on the server before starting rke2
# this can be used to mitigate OS specific issues or configuration
resource "null_resource" "prep" {
  count = (local.server_prep_script == "" ? 0 : 1)
  depends_on = [
    terraform_data.copy_to_remote,
    null_resource.configure,
    null_resource.install_prep,
    time_sleep.ten_s_before_install,
    null_resource.install,
    time_sleep.ten_s_after_install,
    terraform_data.copy_manifests,
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
  provisioner "remote-exec" {
    inline = [<<-EOT
      echo "Connected!"
    EOT
    ]
  }
  provisioner "file" {
    content     = local.server_prep_script
    destination = "${local.remote_workspace}/prep.sh"
  }
  provisioner "remote-exec" {
    inline = [<<-EOT
      set -x
      set -e
      echo "Uptime is "$(sudo uptime | awk '{print $3}' | awk -F: '{print $2}' | awk -F, '{print $1}') min", it should be low."
      sudo chmod +x "${local.remote_workspace}/prep.sh"
      sudo ${local.remote_workspace}/prep.sh
    EOT
    ]
  }
  provisioner "remote-exec" {
    inline = [<<-EOT
      sudo reboot
    EOT
    ]
    on_failure = continue
  }
}
resource "time_sleep" "ten_s_before_start" {
  depends_on = [
    terraform_data.copy_to_remote,
    null_resource.configure,
    null_resource.install_prep,
    time_sleep.ten_s_before_install,
    null_resource.install,
    time_sleep.ten_s_after_install,
    terraform_data.copy_manifests,
    null_resource.prep,
  ]
  create_duration = "10s"
}
# start or restart rke2 service
resource "null_resource" "start" {
  count = (local.start == true ? 1 : 0)
  depends_on = [
    terraform_data.copy_to_remote,
    null_resource.configure,
    null_resource.install_prep,
    time_sleep.ten_s_before_install,
    null_resource.install,
    time_sleep.ten_s_after_install,
    terraform_data.copy_manifests,
    null_resource.prep,
    time_sleep.ten_s_before_start,
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
  provisioner "remote-exec" {
    inline = [<<-EOT
      echo "Connected!"
    EOT
    ]
  }
  provisioner "file" {
    source      = "${abspath(path.module)}/start.sh"
    destination = "${local.remote_workspace}/start.sh"
  }
  provisioner "remote-exec" {
    inline = [<<-EOT
      set -x
      set -e
      echo "Uptime is "$(sudo uptime | awk '{print $3}' | awk -F: '{print $2}' | awk -F, '{print $1}') min", it should be low."
      sudo chmod +x ${local.remote_workspace}/start.sh
      sudo ${local.remote_workspace}/start.sh "${local.role}" "${local.start_timeout}"
    EOT
    ]
  }
}
resource "null_resource" "get_kubeconfig" {
  count = (local.retrieve_kubeconfig == true ? 1 : 0)
  depends_on = [
    terraform_data.copy_to_remote,
    null_resource.configure,
    null_resource.install_prep,
    time_sleep.ten_s_before_install,
    null_resource.install,
    time_sleep.ten_s_after_install,
    terraform_data.copy_manifests,
    null_resource.prep,
    time_sleep.ten_s_before_start,
    null_resource.start,
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
      echo "Connected!"
    EOT
    ]
  }
  provisioner "remote-exec" {
    inline = [<<-EOT
      set -x
      set -e
      sudo cp /etc/rancher/rke2/rke2.yaml "${local.remote_workspace}/kubeconfig"
      sudo chown ${local.ssh_user} "${local.remote_workspace}/kubeconfig"
    EOT
    ]
  }
  provisioner "local-exec" {
    command = <<-EOT
      set -x
      set -e
      FILE="${local.local_path}/kubeconfig"
      REMOTE_PATH="${local.remote_workspace}/kubeconfig"
      IP="${local.ssh_ip}"
      SSH_USER="${local.ssh_user}"

      chmod +x "${abspath(path.module)}/get_kubeconfig.sh"
      "${abspath(path.module)}/get_kubeconfig.sh" "$FILE" "$REMOTE_PATH" "$IP" "$SSH_USER"
    EOT
  }
}
data "local_sensitive_file" "kubeconfig" {
  count = (local.retrieve_kubeconfig == true ? 1 : 0)
  depends_on = [
    terraform_data.copy_to_remote,
    null_resource.configure,
    null_resource.install_prep,
    time_sleep.ten_s_before_install,
    null_resource.install,
    time_sleep.ten_s_after_install,
    terraform_data.copy_manifests,
    null_resource.prep,
    time_sleep.ten_s_before_start,
    null_resource.start,
    null_resource.get_kubeconfig,
  ]
  filename = "${local.local_path}/kubeconfig"
}
