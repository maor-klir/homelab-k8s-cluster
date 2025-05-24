# Connection Variables
variable "proxmox_url" {
  type        = string
  description = "The Proxmox API URL"
}

variable "proxmox_username" {
  type        = string
  description = "The Proxmox username for API operations"
  # default     = "root@pam!terraform"
}

# variable "proxmox_api_token" {
#   type        = string
#   description = "The Proxmox API token"
#   sensitive   = true
# }

variable "proxmox_password" {
  type        = string
  description = "The Proxmox VE user password"
  sensitive   = true
}

variable "proxmox_node" {
  type        = string
  description = "The Proxmox node to build on"
}

# VM Identification
variable "vm_id" {
  type        = string
  description = "The ID for the VM template"
}

# VM ISO Settings
# variable "iso_file" {
#   type        = string
#   description = "The ISO file to use for installation"
# }

# variable "iso_checksum" {
#   type        = string
#   description = "The checksum for the ISO file"
# }

# VM Credentials
variable "ssh_username" {
  type        = string
  description = "The username to use for SSH"
}

variable "ssh_password" {
  type        = string
  description = "The password to use for SSH"
  sensitive   = true
}