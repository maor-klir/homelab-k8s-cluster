terraform {
  required_version = ">= 1.10.0"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = ">= 2.5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=4.50.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">=3.7.0"
    }
  }
}
