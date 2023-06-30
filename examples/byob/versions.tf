terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = ">= 5"
    }
    external = {
      source  = "hashicorp/external"
      version = ">= 2"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2"
    }
  }
}