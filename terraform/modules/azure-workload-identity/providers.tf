terraform {
  required_version = ">= 1.10.0"
  required_providers {
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
}

provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
}
