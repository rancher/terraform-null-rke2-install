variable "release" {
  type        = string
  description = <<-EOT
    The value of the git tag associated with the release to find.
  EOT
}

variable "type" {
  type        = string
  description = <<-EOT
    The designation from the types.tf file to download.
    Types are currently: linux-amd64, linux-s390x, and windows-amd64.
    Amd64 types apply to all x86_64 architectures.
  EOT
}