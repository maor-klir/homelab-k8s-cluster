terraform {
  required_version = ">= 1.10.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.89"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.50"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.7"
    }
  }

  cloud {
    organization = "maor"
    workspaces {
      name = "pve-k3s-qa"
    }
  }
}

provider "proxmox" {
  # Configuration options
  insecure = true
  ssh {
    agent       = false
    private_key = base64decode(var.private_ssh_key)
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
}

provider "azuread" {}
