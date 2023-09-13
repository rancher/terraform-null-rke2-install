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
      install -d ${local.local_path}
      cat << 'EOF' > ${each.key}
      ${local.config_content}
      EOF
    EOT
  }
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      rm -f  ${each.key}
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
  for_each             = (local.local_file_path == "" ? [] : fileset(local.local_path, "*"))
  source               = "${local.local_path}/${each.key}"
  filename             = "${abspath(path.root)}/tmp/${each.key}"
  file_permission      = 0755
  directory_permission = 0755
}

# this is only for tracking changes to files that already exist
resource "local_file" "files_md5" {
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
      ls -lah ${local.remote_path}
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
    script_path = "/home/${local.ssh_user}/rke2_config_terraform"
    agent       = true
    host        = local.ssh_ip
  }
  provisioner "remote-exec" {
    inline = [<<-EOT
      set -x
      set -e
      install -d ${local.remote_path}
      cd ${local.remote_path}
      sudo install -d /etc/rancher/rke2/config.yaml.d
      sudo find ./ -name '*.yaml' -exec cp -prv '{}' '/etc/rancher/rke2/config.yaml.d/' ';'
      sudo ls -lah /etc/rancher/rke2/config.yaml.d
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
    script_path = "/home/${local.ssh_user}/rke2_install_terraform"
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
      sudo chmod +x ${local.remote_path}/install.sh
      sudo INSTALL_RKE2_CHANNEL=${local.release} \
        INSTALL_RKE2_METHOD="tar" \
        INSTALL_RKE2_ARTIFACT_PATH="${local.remote_path}" \
        ${local.remote_path}/install.sh
    EOT
    ]
  }
}
# start or restart rke2 service
resource "null_resource" "start" {
  depends_on = [
    local_file.files_md5,
    local_file.files_source,
    null_resource.copy_to_remote,
    null_resource.configure,
    null_resource.install,
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
      sudo cp /etc/rancher/rke2/rke2.yaml /home/${local.ssh_user}/kubeconfig.yaml
      sudo chown ${local.ssh_user} /home/${local.ssh_user}/kubeconfig.yaml
    EOT
    ]
  }
  provisioner "local-exec" {
    command = <<-EOT
      set -x
      set -e
      scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${local.ssh_user}@${local.ssh_ip}:/home/${local.ssh_user}/kubeconfig.yaml ${abspath(path.root)}/kubeconfig-${local.identifier}.yaml
      sed -i "s/127.0.0.1/${local.ssh_ip}/g" "${abspath(path.root)}/kubeconfig-${local.identifier}.yaml" || sed -i '' "s/127.0.0.1/${local.ssh_ip}/g" "${abspath(path.root)}/kubeconfig-${local.identifier}.yaml"
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
  ]
  filename = "${abspath(path.root)}/kubeconfig-${local.identifier}.yaml"
}
