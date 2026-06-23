terraform {
  required_version = ">= 1.5.0"
  required_providers {
    file = {
      source  = "rancher/file"
      version = ">= 1.7.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.12"
    }
  }
}
