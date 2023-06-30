terraform {
  required_providers {
    github = {
      source = "integrations/github"
    }
    local = {
      source = "hashicorp/local"
    }
    external = {
      source = "hashicorp/external"
    }
  }
}
