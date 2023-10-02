locals {
  release             = var.release
  role                = var.role
  ssh_ip              = var.ssh_ip
  ssh_user            = var.ssh_user
  identifier          = var.identifier
  local_file_path     = var.local_file_path # since logic is determined by this variable, it will not be able to be set by a module
  local_path          = (local.local_file_path == "" ? "${abspath(path.root)}/rke2" : local.local_file_path)
  remote_path         = (var.remote_file_path == "" ? "/home/${local.ssh_user}/rke2_artifacts" : var.remote_file_path)
  config_content      = var.rke2_config
  retrieve_kubeconfig = var.retrieve_kubeconfig
  install_method      = var.install_method
  server_prep_script  = var.server_prep_script
}

resource "null_resource" "write_config" {
  # the name needs to be something highly unlikely to be used by a user, so that we don't clobber any of their configs
  # we also want the name to be easily recognizable for what it is (the initially generated config)
  # we also want the name to have an index so that users can supply their own configs before or after this one (they are merged alphabetically)
  # the name should use dashes instead of underscores, as a matter of convention (marginally helps sorting)
  for_each = (local.local_file_path == "" ? [] : toset(["${local.local_path}/50-initial-generated-config.yaml"]))
  triggers = {
    config_content = local.config_content,
  }
  provisioner "local-exec" {
    command = <<-EOT
      set -e
      set -x
      chmod +x "${abspath(path.module)}/write_config.sh"
      "${abspath(path.module)}/write_config.sh" "${local.local_path}" "${each.key}" "${local.config_content}"
    EOT
  }
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      rm -f "${each.key}"
    EOT
  }
}

# this module assumes that any *.yaml files in the path are meant to be copied to the config directory
# we don't want to manage the files in case the user is managing them with another tool
# we do need to know when the files change so we can run the install script and restart the service
## so we use a local_file data source to track tmp files that are created from the local_path
# if a local path was not provided we don't need to track anything

# this should track files that don't exist until apply time
resource "local_file" "files_source" {
  depends_on           = [null_resource.write_config]
  for_each             = (local.local_file_path == "" ? [] : fileset(local.local_path, "*"))
  source               = "${local.local_path}/${each.key}"
  filename             = "${abspath(path.root)}/tmp/${each.key}"
  file_permission      = 0755
  directory_permission = 0755
}

# this is only for tracking changes to files that already exist
resource "local_file" "files_md5" {
  depends_on = [
    null_resource.write_config,
    local_file.files_source,
  ]
  for_each             = (local.local_file_path == "" ? [] : fileset(local.local_path, "*"))
  content              = filemd5("${local.local_path}/${each.key}")
  filename             = "${abspath(path.root)}/tmp/${each.key}.md5"
  file_permission      = 0755
  directory_permission = 0755
}

# if local path specified copy all files and folders to the remote_path directory
resource "null_resource" "copy_to_remote" {
  count = (local.local_file_path == "" ? 0 : 1)
  depends_on = [
    null_resource.write_config,
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
    script_path = "/home/${local.ssh_user}/rke2_copy_terraform"
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
    null_resource.write_config,
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
    script_path = "/home/${local.ssh_user}/rke2_config_terraform"
    agent       = true
    host        = local.ssh_ip
  }
  provisioner "file" {
    source      = "${abspath(path.module)}/configure.sh"
    destination = "/home/${local.ssh_user}/configure.sh"
  }
  provisioner "remote-exec" {
    inline = [<<-EOT
      set -x
      set -e
      sudo chmod +x /home/${local.ssh_user}/configure.sh
      sudo /home/${local.ssh_user}/configure.sh "${local.remote_path}"
    EOT
    ]
  }
}
# optionally run a script on the server before installing rke2
# this can be used to mitigate OS specific issues or configuration
resource "null_resource" "prep" {
  count = (local.server_prep_script == "" ? 0 : 1)
  depends_on = [
    null_resource.write_config,
    local_file.files_md5,
    local_file.files_source,
    null_resource.copy_to_remote,
    null_resource.configure,
  ]
  triggers = {
    release = local.release,
    id      = local.identifier,
    script  = local.server_prep_script,
  }
  connection {
    type        = "ssh"
    user        = local.ssh_user
    script_path = "/home/${local.ssh_user}/rke2_server_prep_terraform"
    agent       = true
    host        = local.ssh_ip
  }
  provisioner "file" {
    content     = local.server_prep_script
    destination = "/home/${local.ssh_user}/prep.sh"
  }
  provisioner "remote-exec" {
    inline = [<<-EOT
      set -x
      set -e
      sudo chmod +x "/home/${local.ssh_user}/prep.sh"
      sudo /home/${local.ssh_user}/prep.sh
    EOT
    ]
  }
}
# run the install script, which may upgrade rke2 if it is already installed
resource "null_resource" "install" {
  depends_on = [
    null_resource.write_config,
    local_file.files_md5,
    local_file.files_source,
    null_resource.copy_to_remote,
    null_resource.configure,
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
    script_path = "/home/${local.ssh_user}/rke2_install_terraform"
    agent       = true
    host        = local.ssh_ip
  }
  provisioner "file" {
    source      = "${abspath(path.module)}/install.sh"
    destination = "/home/${local.ssh_user}/install.sh"
  }
  provisioner "remote-exec" {
    inline = [<<-EOT
      set -x
      set -e
      sudo chmod +x "/home/${local.ssh_user}/install.sh"
      sudo /home/${local.ssh_user}/install.sh "${local.role}" "${local.remote_path}" "${local.release}" "${local.install_method}"
    EOT
    ]
  }
}
# start or restart rke2 service
resource "null_resource" "start" {
  depends_on = [
    null_resource.write_config,
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
    script_path = "/home/${local.ssh_user}/rke2_start_terraform"
    agent       = true
    host        = local.ssh_ip
  }
  provisioner "file" {
    source      = "${abspath(path.module)}/start.sh"
    destination = "/home/${local.ssh_user}/start.sh"
  }
  provisioner "remote-exec" {
    inline = [<<-EOT
      set -x
      set -e
      sudo chmod +x /home/${local.ssh_user}/start.sh
      sudo /home/${local.ssh_user}/start.sh "${local.role}"
    EOT
    ]
  }
}
resource "null_resource" "get_kubeconfig" {
  count = (local.retrieve_kubeconfig == true ? 1 : 0)
  depends_on = [
    null_resource.write_config,
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
    script_path = "/home/${local.ssh_user}/get_kubeconfig_terraform"
    agent       = true
    host        = local.ssh_ip
  }
  provisioner "remote-exec" {
    inline = [<<-EOT
      set -x
      set -e
      sudo cp /etc/rancher/rke2/rke2.yaml "/home/${local.ssh_user}/kubeconfig.yaml"
      sudo chown ${local.ssh_user} "/home/${local.ssh_user}/kubeconfig.yaml"
    EOT
    ]
  }
  provisioner "local-exec" {
    command = <<-EOT
      set -x
      set -e
      FILE="${abspath(path.root)}/kubeconfig-${local.identifier}.yaml"
      REMOTE_PATH="/home/${local.ssh_user}/kubeconfig.yaml"
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
    null_resource.write_config,
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
