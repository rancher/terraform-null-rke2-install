terraform {
  required_version = ">= 1.2.0"
  required_providers {
    github = {
      source  = "integrations/github"
      version = ">= 5.32"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4"
    }
    # NOTE: this is only required for the examples
    # this is used by the aws_access and aws_server modules
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.11"
    }
    # NOTE: this is only required for the examples
    # this is used by the aws_access module
    http = {
      source  = "hashicorp/http"
      version = ">= 3.4"
    }
  }
}