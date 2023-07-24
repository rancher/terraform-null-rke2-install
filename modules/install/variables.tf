variable "identifier" {
  type        = string
  description = <<-EOT
    A unique identifier for the server to install RKE2 on.
    This is used to align the resources in this module with your server lifecycle.
    While the content of this value remains the same, the resources will not be recreated.
    If this value is changed, the resources will be recreated.
    This allows you to manage your server lifecycle separate from your RKE2 lifecycle.
  EOT
}
variable "ssh_ip" {
  type        = string
  description = <<-EOT
    The IP address of the server to install RKE2 on.
    We will attempt to open an ssh connection on this IP address.
    Ssh port must be open and listening, and the user must have sudo/admin privileges.
    This script will only run the install script, please ensure that the server is ready.
  EOT
  default     = ""
}
variable "ssh_user" {
  type        = string
  description = <<-EOT
    The user to log into the server to install RKE2 on.
    We will attempt to open an ssh connection with this user.
    The user must have sudo/admin privileges.
    This script will only run the install script, please ensure that the server is ready.
  EOT
  default     = ""
}
variable "path" {
  type        = string
  description = <<-EOT
    The directory path where the files exist.
    It is expected that some files are compressed, and will be uncompressed on the remote machine.
    The machine should have a version of tar that supports the -z flag.
  EOT
  default     = ""
}
variable "release" {
  type        = string
  description = <<-EOT
    The version of RKE2 to install.
  EOT
}
variable "arch" {
  type        = string
  description = <<-EOT
    The architecture of the server to download for.
    Currently supported values are 'amd64' and 's390x'.
    Use 'amd64' for all x86_64 systems.
  EOT
}
variable "system" {
  type        = string
  description = <<-EOT
    The system of the server to download for.
    The only supported value is 'linux'.
  EOT 
}
variable "expected_files" {
  type        = list(string)
  description = <<-EOT
    A list of files that are expected to be in the path.
  EOT 
}