terraform {
  required_version = ">= 1.10.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.89.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5.3"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=4.50.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">=3.7.0"
    }
    tfe = {
      source  = "hashicorp/tfe"
      version = ">=0.71.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">=0.12.0"
    }
  }

  cloud {
    organization = "maor"
    workspaces {
      name = "pve-k3s"
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
  subscription_id = var.azure_subscription_id
  features {}
}

provider "azurerm" {
  alias           = "maors-dev-env"
  subscription_id = var.azure_subscription_id
  features {}
}

provider "azuread" {
}

provider "tfe" {
}
