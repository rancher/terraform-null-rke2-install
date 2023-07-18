variable "release" {
  type        = string
  description = <<-EOT
    The version of RKE2 to install.
    If using the local_file_path variable, this should match the release version of the files in the directory.
    Defaults to 'latest'.
  EOT
  default     = "latest"
}
variable "arch" {
  type        = string
  description = <<-EOT
    The architecture of the server to install RKE2 on.
    The current supported architectures are: 'amd64' and 's390x'.
    Use "amd64" for all x86_64 architectures.
  EOT
  default     = "amd64"
}
variable "system" {
  type        = string
  description = <<-EOT
    The OS system of the server to install RKE2 on.
    Currently, the only supported type is: 'linux'.
  EOT
  default     = "linux"
}
variable "local_file_path" {
  type        = string
  description = <<-EOT
    The path to the directory for the files to use instead of downloading.
    The files should be renamed to match the designations in ./modules/download/types.tf.
    Currently, the designations are: rke2-images.tar.gz, rke2.tar.gz, sha256sum.txt, and rke2-install.
    This is useful if the server that is running Terraform does not have access to GitHub.
    eg. '/tmp/rke2' contains '/tmp/rke2/rke2-images.tar.gz'
    If local_file_path is set, downloads will not be attempted.
  EOT
  default     = ""
}
variable "ssh_ip" {
  type        = string
  description = <<-EOT
    The IP address of the server to install RKE2 on.
    We will attempt to open an ssh connection on this IP address.
    Ssh port must be open and listening, and the user must have sudo/admin privileges.
    This script will only run the install script, please ensure that the server is ready.
  EOT
}
variable "ssh_user" {
  type        = string
  description = <<-EOT
    The user to log into the server to install RKE2 on.
    We will attempt to open an ssh connection with this user.
    The user must have sudo/admin privileges.
    This script will only run the install script, please ensure that the server is ready.
  EOT
}
variable "rke2_config" {
  type        = string
  description = <<-EOT
    The content of the RKE2 `config.yaml` to use.
    If this is not set, the module looks in the 'local_file_path' directory for a file named 'rke2-config.yaml'.
    If that file does not exist or 'local_file_path' is not set, the module will use the default configuration.
  EOT
  default     = ""
}