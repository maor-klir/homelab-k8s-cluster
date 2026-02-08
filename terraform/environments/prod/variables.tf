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

variable "control_plane_count" {
  description = "Number of control plane nodes"
  type        = number
  default     = 1
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 3
}

variable "base_ip_address" {
  description = "Base IP address for the VMs"
  type        = string
  default     = "192.168.0."
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

variable "k3s_token" {
  description = "K3s cluster token for joining nodes"
  type        = string
  sensitive   = true
}

################################################################
##### Azure variables for workload identity implementation #####
################################################################

variable "azure_subscription_id" {
  type        = string
  description = "Azure Subscription ID where resources will be created"
}

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

######################################
##### Azure variables for Thanos #####
######################################

variable "thanos_storage_account_name" {
  type        = string
  description = "Thanos storage account name"
}

# General observability stack resource group
variable "observability_rg" {
  type        = string
  description = "Observability resource group name"
}

#################################
### LXC cluster load balancer ###
#################################

variable "lxc_lb_count" {
  type        = number
  description = "The count of the LXC cluster load balancer containers"
}

variable "lxc_lb_id_start" {
  type        = string
  description = "First IP address of the LXC cluster load balancer stack"
}

variable "lxc_lb_memory" {
  description = "Memory allocation for LXC cluster load balancer container (in MB)"
  type        = number
  default     = 512
}

variable "lxc_lb_cores" {
  description = "CPU cores for LXC cluster load balancer container"
  type        = number
  default     = 2
}

variable "lxc_gateway" {
  description = "Default gateway for LXC cluster load balancer"
  type        = string
  default     = "192.168.0.1"
}

variable "lxc_subnet_mask" {
  description = "Subnet mask in CIDR notation"
  type        = string
  default     = "24"
}

variable "lb_public_key" {
  description = "Load balancer LXC user SSH public key"
  type        = string
}

######################################
##### Azure variables for Loki #######
######################################

variable "loki_storage_account_name" {
  type        = string
  description = "Loki storage account name"
}
