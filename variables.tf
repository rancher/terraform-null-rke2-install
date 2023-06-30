variable "release" {
  type        = string
  description = <<-EOT
    The version of RKE2 to install.
    If local_file_path is set, the type and release variables are ignored.
  EOT
  default     = ""
}
variable "type" {
  type        = string
  description = <<-EOT
    The designation from the types.tf file to download.
    Types are currently: linux-amd64, linux-s390x, and windows-amd64.
    Amd64 types apply to all x86_64 architectures.
    If local_file_path is set, the type and release variables are ignored.
  EOT
  default     = ""
}
variable "local_file_path" {
  type        = string
  description = <<-EOT
    The path to the directory for the files to use instead of downloading.
    The files should be renamed to match the designations in ./modules/download/types.tf.
    Currently, the designations are: rke2-images.tar.gz and rke2.tar.gz.
    This is useful if the server that is running Terraform does not have access to GitHub.
    If local_file_path is set, the type and release variables are ignored.
  EOT
  default     = ""
}