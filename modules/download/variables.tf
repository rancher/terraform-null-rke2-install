variable "release" {
  type        = string
  description = <<-EOT
    The value of the git tag associated with the release to find.
    Use 'latest' to find the latest release.
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
