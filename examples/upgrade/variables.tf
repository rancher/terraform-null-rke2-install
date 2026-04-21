variable "identifier" {
  type = string
}
variable "key" {
  type = string
}
variable "key_name" {
  type = string
}
variable "rke2_version" {
  type        = string
  description = "RKE2 version to install. Change this value to upgrade RKE2."
  default     = "v1.34.6+rke2r3" # To upgrade, change to v1.35.3+rke2r3
}
