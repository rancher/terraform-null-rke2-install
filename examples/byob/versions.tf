terraform {
  required_version = ">= 1.2.0"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.1"
    }
    github = {
      source  = "integrations/github"
      version = ">= 5.32"
    }
  }
}
provider "github" {
  token    = ""
  base_url = "https://localhost"
}
