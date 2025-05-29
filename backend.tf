terraform {
  required_version = ">= 1.5"
  backend "remote" {
    organization = "AutomAItion"
    workspaces { name = "n8n-vault" }
  }
}
