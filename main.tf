locals {
  release             = var.release
  role                = var.role
  ssh_ip              = var.ssh_ip
  ssh_user            = var.ssh_user
  identifier          = var.identifier
  local_file_path     = var.local_file_path
  local_path          = (local.local_file_path == "" ? "${abspath(path.root)}/rke2" : local.local_file_path)
  remote_workspace    = (var.remote_workspace == "" ? "/home/${local.ssh_user}" : var.remote_workspace)
  remote_path         = (var.remote_file_path == "" ? "${local.remote_workspace}/rke2_artifacts" : var.remote_file_path)
  retrieve_kubeconfig = var.retrieve_kubeconfig
  install_method      = var.install_method
  server_prep_script  = var.server_prep_script
  start               = var.start
}

# this module assumes that any *.yaml files in the path are meant to be copied to the config directory
# we don't want to manage the files in case the user is managing them with another tool
# we do need to know when the files change so we can run the install script and restart the service
## so we use a local_file data source to track tmp files that are created from the local_file_path
# if a local path was not provided we don't need to track anything

# this should track files that don't exist until apply time
resource "local_file" "files_source" {
  for_each             = fileset(local.local_path, "*")
  source               = "${local.local_path}/${each.key}"
  filename             = "${abspath(path.root)}/tmp/${each.key}"
  file_permission      = 0755
  directory_permission = 0755
}

# this is only for tracking changes to files that already exist
resource "local_file" "files_md5" {
  depends_on = [
    local_file.files_source,
  ]
  for_each             = fileset(local.local_path, "*")
  content              = filemd5("${local.local_path}/${each.key}")
  filename             = "${abspath(path.root)}/tmp/${each.key}.md5"
  file_permission      = 0755
  directory_permission = 0755
}

# if local path specified copy all files and folders to the remote_path directory
resource "null_resource" "copy_to_remote" {
  depends_on = [
    local_file.files_md5,
    local_file.files_source,
  ]
  triggers = {
    files_md5 = jsonencode(local_file.files_md5[*]),
    files_src = jsonencode(local_file.files_source[*]),
    release   = local.release,
    id        = local.identifier,
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
    local_file.files_md5,
    local_file.files_source,
    null_resource.copy_to_remote,
  ]
  triggers = {
    files_md5 = jsonencode(local_file.files_md5[*]),
    files_src = jsonencode(local_file.files_source[*]),
    release   = local.release,
    id        = local.identifier,
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
    local_file.files_md5,
    local_file.files_source,
    null_resource.copy_to_remote,
    null_resource.configure,
  ]
  triggers = {
    files_md5 = jsonencode(local_file.files_md5[*]),
    files_src = jsonencode(local_file.files_source[*]),
    release   = local.release,
    id        = local.identifier,
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
      sudo ${local.remote_workspace}/install.sh "${local.role}" "${local.remote_path}" "${local.release}" "${local.install_method}"
    EOT
    ]
  }
}
# optionally run a script on the server before starting rke2
# this can be used to mitigate OS specific issues or configuration
resource "null_resource" "prep" {
  count = (local.server_prep_script == "" ? 0 : 1)
  depends_on = [
    local_file.files_md5,
    local_file.files_source,
    null_resource.copy_to_remote,
    null_resource.configure,
    null_resource.install,
  ]
  triggers = {
    release = local.release,
    id      = local.identifier,
    script  = local.server_prep_script,
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
    local_file.files_md5,
    local_file.files_source,
    null_resource.copy_to_remote,
    null_resource.configure,
    null_resource.install,
    null_resource.prep,
  ]
  triggers = {
    files_md5 = jsonencode(local_file.files_md5[*]),
    files_src = jsonencode(local_file.files_source[*]),
    release   = local.release,
    id        = local.identifier,
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
      sudo ${local.remote_workspace}/start.sh "${local.role}"
    EOT
    ]
  }
}
resource "null_resource" "get_kubeconfig" {
  count = (local.retrieve_kubeconfig == true ? 1 : 0)
  depends_on = [
    local_file.files_md5,
    local_file.files_source,
    null_resource.copy_to_remote,
    null_resource.configure,
    null_resource.install,
    null_resource.start,
    null_resource.prep,
  ]
  triggers = {
    files_md5 = jsonencode(local_file.files_md5[*]),
    files_src = jsonencode(local_file.files_source[*]),
    release   = local.release,
    id        = local.identifier,
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
      FILE="${abspath(path.root)}/kubeconfig-${local.identifier}.yaml"
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
    local_file.files_md5,
    local_file.files_source,
    null_resource.copy_to_remote,
    null_resource.configure,
    null_resource.install,
    null_resource.start,
    null_resource.get_kubeconfig,
    null_resource.prep,
  ]
  filename = "${abspath(path.root)}/kubeconfig-${local.identifier}.yaml"
}
