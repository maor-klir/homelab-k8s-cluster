# Connection Variables

variable "proxmox_url" {
  type        = string
  description = "The Proxmox API URL"
}

variable "proxmox_username" {
  type        = string
  description = "The Proxmox username for API operations"
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
  description = "The ID of the VM template"
}

variable "vm_id_clone" {
  type        = string
  description = "The ID of the cloned VM template"
  default     = "7001"
}

# VM ISO Settings

variable "iso_file" {
  type        = string
  description = "The ISO file to use for installation"
}

variable "iso_checksum" {
  type        = string
  description = "The checksum for the ISO file"
}

# VM Credentials

variable "ssh_username" {
  type        = string
  description = "The username to use for the Packer SSH communicator"
}

variable "ssh_public_key" {
  type        = string
  description = "The public key to use for SSH"
}

variable "ssh_private_key_file" {
  type        = string
  description = "The path to the private key file for SSH"
}

# variable "ssh_password" {
#   type        = string
#   description = "The password to use for the Packer SSH communicator"
#   sensitive   = true
# }