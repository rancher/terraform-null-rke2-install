variable "key" {
  type        = string
  description = "The content of the public ssh key to use."
}
variable "key_name" {
  type        = string
  description = "The name of the ssh key pair to use, must already exist in AWS and have a corresponding 'Name' tag."
}
variable "rke2_version" {
  type        = string
  description = "The version of rke2 to install, must be a valid tag name like v1.21.6+rke2r1."
}
variable "identifier" {
  type        = string
  description = <<-EOT
    A unique identifier for the test, this is used to ensure that test objects do not collide.
    Must be less than 10 characters, and only contain lowercase letters and numbers.
  EOT
}
