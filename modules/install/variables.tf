variable "identifier" {
  type        = string
  description = <<-EOT
    A unique identifier for the server to install RKE2 on.
  EOT
}
variable "ssh_ip" {
  type        = string
  description = <<-EOT
    The IP address of the server to install RKE2 on.
  EOT
}
variable "ssh_user" {
  type        = string
  description = <<-EOT
    The user to log into the server to install RKE2 on.
  EOT
}
variable "path" {
  type        = string
  description = <<-EOT
    The directory path where the files exist.
  EOT
}
variable "release" {
  type        = string
  description = <<-EOT
    The version of RKE2 to install.
  EOT
}
variable "role" {
  type        = string
  description = <<-EOT
    The kubernetes role of the server to install RKE2 on.
    May be 'server' or 'agent'.
  EOT 
}
