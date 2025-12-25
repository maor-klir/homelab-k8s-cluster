# Variable definitions for Proxmox Virtual Environment (PVE) setup
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

# K3s cluster configuration variables
variable "environment" {
  description = "Environment name (qa, prod)"
  type        = string
  validation {
    condition     = contains(["qa", "prod"], var.environment)
    error_message = "Environment must be either 'qa' or 'prod'."
  }
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

variable "vm_id_start" {
  description = "Starting VM ID for the VMs"
  type        = number
}

variable "control_plane_memory" {
  description = "Memory allocation for control plane nodes in MB"
  type        = number
  default     = 8192
}

variable "control_plane_cores" {
  description = "CPU cores for control plane nodes"
  type        = number
  default     = 2
}

variable "worker_memory" {
  description = "Memory allocation for worker nodes in MB"
  type        = number
  default     = 8192
}

variable "worker_cores" {
  description = "CPU cores for worker nodes"
  type        = number
  default     = 2
}

variable "gateway" {
  description = "Default gateway for VMs"
  type        = string
  default     = "192.168.0.1"
}

variable "subnet_mask" {
  description = "Subnet mask in CIDR notation"
  type        = string
  default     = "24"
}

# cloud-init variables
variable "user_data_general" {
  description = "cloud-init general user data template file path"
  type        = string
  default     = "cloud-init/general.yaml.tftpl"
}

variable "user_data_control_plane" {
  description = "cloud-init user data template for the control plane nodes"
  type        = string
  default     = "cloud-init/control-plane.yaml.tftpl"
}

variable "user_data_worker" {
  description = "cloud-init user data template for the worker nodes"
  type        = string
  default     = "cloud-init/worker.yaml.tftpl"
}

variable "k3s_vm_dns" {
  description = "DNS configuration for K3s VMs"
  type = object({
    domain  = string
    servers = list(string)
  })
}

variable "k3s_vm_user" {
  description = "K3s VM username"
  type        = string
  default     = "k3s"
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

variable "k3s_cluster_port" {
  description = "K3s API server port"
  type        = number
  default     = 6443
}
