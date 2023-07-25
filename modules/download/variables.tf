variable "release" {
  type        = string
  description = <<-EOT
    The value of the git tag associated with the release to find.
    Use 'latest' to find the latest release.
  EOT
}

variable "files" {
  type        = list(string)
  description = <<-EOT
    The files to download.
  EOT 
}
