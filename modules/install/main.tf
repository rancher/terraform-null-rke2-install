locals {
  identifier  = var.identifier
  ssh_ip      = var.ssh_ip
  ssh_user    = var.ssh_user
  release     = var.release
  role        = var.role
  local_path  = var.path
  remote_path = "/home/${local.ssh_user}/rke2_artifacts"
  #  file_content_sha = sha256(join(",", [for f in fileset(local.local_path, "**") : sha256("${local.local_path}/${f}")]))
}

# this module assumes that any *.yaml files in the path are meant to be copied to the config directory
# we don't want to manage the files in case the user is managing them with another tool
# we do need to know when the files change so we can run the install script and restart the service
## so we use a local_file data source to track tmp files that are created from the local_path

# need a resource for tracking files that don't exist until apply time
# data "local_file" "files" {
#   for_each = fileset(local.local_path, "**") #{ for f in fileset(local.local_path, "**") : f => sha256("${local.local_path}/${f}") }
#   filename = "${local.local_path}/${each.key}"
# }

# this should track files that don't exist until apply time
resource "local_file" "files_source" {
  for_each = fileset(local.local_path, "*")
  source   = "${local.local_path}/${each.key}"
  filename = "${path.root}/tmp/${each.key}"
}

# this is only for tracking changes to files that already exist
resource "local_file" "files_md5" {
  for_each = fileset(local.local_path, "*")
  content  = filemd5("${local.local_path}/${each.key}")
  filename = "${path.root}/tmp/${each.key}.md5"
}

# copy all files and folders in the local_path to the remote_path directory
resource "null_resource" "copy_to_remote" {
  depends_on = [
    local_file.files_md5,
    local_file.files_source,
  ]
  triggers = {
    files_md5 = jsonencode(local_file.files_md5.*),
    files_src = jsonencode(local_file.files_source.*),
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
# copy all yaml files into the config directory
resource "null_resource" "configure" {
  depends_on = [
    local_file.files_md5,
    local_file.files_source,
    null_resource.copy_to_remote,
  ]
  triggers = {
    files_md5 = jsonencode(local_file.files_md5.*),
    files_src = jsonencode(local_file.files_source.*),
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
    files_md5 = jsonencode(local_file.files_md5.*),
    files_src = jsonencode(local_file.files_source.*),
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
    files_md5 = jsonencode(local_file.files_md5.*),
    files_src = jsonencode(local_file.files_source.*),
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
