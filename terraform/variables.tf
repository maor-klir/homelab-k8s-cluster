variable "pve_node_name" {
  description = "The Proxmox Virtual Environment node names where the VMs will be created"
  type        = list(string)
  default     = ["pve-01", "pve-02", "pve-03"]
}

variable "private_ssh_key" {
  description = "The private SSH key content for accessing the Proxmox server"
  type        = string
  sensitive   = true
}

variable "k3s_vm_dns" {
  description = "DNS config for the K3s VMs"
  type = object({
    domain  = string
    servers = list(string)
  })
}

variable "k3s_vm_user" {
  description = "K3s VM username"
  type        = string
}

variable "k3s_public_key" {
  description = "K3s user public key"
  type        = string
}

# variable "cilium-cli-version" {
#   description = "Cilium CLI version"
#   type        = string
# }
########################################################################################
##### Azure variables for HCP Terraform integration - Dynamic provider credentials #####
########################################################################################

variable "hcpt_azure_audience" {
  type        = string
  default     = "api://AzureADTokenExchange"
  description = "The audience value to use in run identity tokens"
}

variable "hcpt_hostname" {
  type        = string
  default     = "app.terraform.io"
  description = "The hostname of the HCP Terraform or TFE instance we'd like to use with Azure"
}

variable "hcpt_organization_name" {
  type        = string
  default     = "maor"
  description = "The name of our HCP Terraform organization"
}

variable "hcpt_project_name" {
  type        = string
  default     = "Default Project"
  description = "The project under which a workspace will be created"
}

variable "hcpt_workspace_name" {
  type        = string
  description = "The name of the workspace that we'd like to create and connect to Azure"
}

variable "azure_subscription_id" {
  type        = string
  description = "Azure Subscription ID where resources will be created"
}

################################################################
##### Azure variables for workload identity implementation #####
################################################################

variable "oidc_rg" {
  type        = string
  description = "OIDC issuer resource group"
}

variable "oidc_rg_location" {
  type        = string
  description = "OIDC issuer resource group location"
  default     = "West Europe"
}

variable "oidc_storage_account" {
  type        = string
  description = "OIDC issuer storage account name"
}

variable "oidc_storage_container" {
  type        = string
  description = "OIDC issuer storage container name"
}

variable "azwi_rg" {
  type        = string
  description = "Azure Workload Identity resource group name"
}

variable "azwi_rg_location" {
  type        = string
  description = "Azure Workload Identity resource group location"
  default     = "West Europe"
}

variable "akv_azwi_name" {
  type        = string
  description = "Azure Key Vault for Azure Workload Identity name"
}

variable "akv_azwi_location" {
  type        = string
  description = "Azure Key Vault for Azure Workload Identity location"
  default     = "West Europe"
}

variable "azwi_service_account_namespace" {
  type        = string
  description = "Kubernetes namespace for the Azure Workload Identity service account"
  default     = "external-secrets-operator"
}

variable "azwi_service_account_name" {
  type        = string
  description = "Kubernetes service account name for Azure Workload Identity"
  default     = "workload-identity-sa"
}
