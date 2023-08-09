variable "release" {
  type        = string
  description = <<-EOT
    The version of RKE2 to install.
    If using the local_file_path variable, this should match the release version of the files in the directory.
    Must be a valid version, not "latest", eg. "v1.27.3+rke2r1".
  EOT
  validation {
    condition     = can(regex("v[0-9]+\\.[0-9]+\\.[0-9]+\\+rke2r[0-9]+", var.release))
    error_message = "Must be a valid version, not 'latest', eg. 'v1.27.3+rke2r1'."
  }
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
variable "role" {
  type        = string
  description = <<-EOT
    The kubernetes role of the server to install RKE2 on.
    May be 'server' or 'agent', defaults to 'server'.
  EOT
  default     = "server"
}
variable "local_file_path" {
  type        = string
  description = <<-EOT
    The path to the directory for the files to use instead of downloading. eg. "/tmp/rke2"
    Files must match expected file names:     
      "rke2-images.<system>-<arch>.tar.gz",
      "rke2.<system>-<arch>.tar.gz",
      "sha256sum-<arch>.txt",
      "install.sh",
    This is useful if the server that is running Terraform does not have access to GitHub.
    If local_file_path is set, downloads will not be attempted.
    You may need to set a dummy provider config for the GitHub provider if you use this:
    provider "github" {
      token    = ""
      base_url = "https://localhost"
    }
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
    If that file does not exist or 'local_file_path' is not set, the module will use an empty configuration.
    This is affected by the 'config_file_name' variable; you can supply json content instead of yaml.
  EOT
  default     = ""
}
variable "server_identifier" {
  type        = string
  description = <<-EOT
    A unique identifier for the server to install RKE2 on.
    This is used to align the resources in this module with your server lifecycle.
    If this value is changed, the resources will be recreated.
    This allows you to manage your server lifecycle separate from your RKE2 lifecycle.
  EOT
}
