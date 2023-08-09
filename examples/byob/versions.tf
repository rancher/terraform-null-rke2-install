terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = ">= 2"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3"
    }
    github = {
      source  = "integrations/github"
      version = ">= 5"
    }
  }
}
provider "github" {
  token    = ""
  base_url = "https://localhost"
}
