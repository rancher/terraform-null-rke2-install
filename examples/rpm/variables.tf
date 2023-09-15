variable "key" {
  type    = string
  default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ4HmZ/KHZ/8KsvYlz6wqpoWoOaH1edHId2aK6niqKIw terraform-ci@suse.com"
}
variable "key_name" {
  type    = string
  default = "terraform-ci"
}
variable "rke2_version" {
  type    = string
  default = "v1.27.4+rke2r1"
}
variable "identifier" {
  type        = string
  description = <<-EOT
    A unique identifier for the test, this is used to ensure that test objects do not collide.
    Must be less than 10 characters, and only contain lowercase letters and numbers.
  EOT
}