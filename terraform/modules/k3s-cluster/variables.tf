variable "private_ssh_key" {
  description = "The private SSH key content for accessing the Proxmox server"
  type        = string
  sensitive   = true
}

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
}

variable "vm_id_start" {
  description = "Starting VM ID for the VMs"
  type        = number
}

variable "pve_nodes" {
  description = "List of Proxmox node names for VM placement"
  type        = list(string)
}

variable "k3s_vm_dns" {
  description = "DNS configuration for K3s VMs"
  type = object({
    domain  = string
    servers = list(string)
  })
}

variable "k3s_vm_user" {
  description = "Username for K3s VMs"
  type        = string
}

variable "k3s_public_key" {
  description = "SSH public key for K3s user"
  type        = string
}

variable "control_plane_memory" {
  description = "Memory allocation for control plane nodes in MB"
  type        = number
  default     = 16384
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
