variable "environment" {
  description = "Environment name (qa, prod)"
  type        = string
  validation {
    condition     = contains(["qa", "prod"], var.environment)
    error_message = "Environment must be either 'qa' or 'prod'."
  }
}

# variable "azure_subscription_id" {
#   description = "Azure Subscription ID"
#   type        = string
# }

variable "oidc_rg" {
  description = "OIDC issuer resource group name"
  type        = string
}

variable "oidc_rg_location" {
  description = "OIDC issuer resource group location"
  type        = string
  default     = "West Europe"
}

variable "oidc_storage_account" {
  description = "OIDC issuer storage account name"
  type        = string
}

variable "oidc_storage_container" {
  description = "OIDC issuer storage container name"
  type        = string
  default     = "$web"
}

variable "azwi_rg" {
  description = "Azure Workload Identity resource group name"
  type        = string
}

variable "azwi_rg_location" {
  description = "Azure Workload Identity resource group location"
  type        = string
  default     = "West Europe"
}

variable "akv_azwi_name" {
  description = "Azure Key Vault for Azure Workload Identity name"
  type        = string
}

variable "akv_azwi_location" {
  description = "Azure Key Vault for Azure Workload Identity location"
  type        = string
  default     = "West Europe"
}

variable "azwi_service_account_namespace" {
  description = "Kubernetes namespace for the Azure Workload Identity service account"
  type        = string
  default     = "external-secrets-operator"
}

variable "azwi_service_account_name" {
  description = "Kubernetes service account name for Azure Workload Identity"
  type        = string
  default     = "workload-identity-sa"
}

variable "jwks_file_path" {
  description = "Path to the JWKS JSON file"
  type        = string
}
