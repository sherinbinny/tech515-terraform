terraform {
  required_providers {
    github = {
        source = "integrations/github"
        version = "~> 5.0"
    }
  }
}

provider "github" {
  # Token picked up from GITHUB_TOKEN env variable
  owner = var.owner_name
}

resource "github_repository" "new_repo" {
  name = var.github_repo_name
  description = var.github_repo_description
  visibility = var.visibility
  auto_init   = true  # optional, initializes with README
}