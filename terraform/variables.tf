# variable "proxmox" {
#   description = "Proxmox provider configuration"
#   type = object({
#     node_name = string
#     endpoint  = string
#     insecure  = bool
#     username  = string
#     password  = string
#   })
# }

variable "proxmox_api_token" {
  description = "Proxmox API token"
  type        = string
  sensitive   = true
}

variable "vm_hostname" {
  description = "VM hostname"
  type        = string
}

variable "vm_username" {
  description = "VM username"
  type        = string
}

variable "vm_password" {
  description = "VM password"
  type        = string
  sensitive   = true
}

# variable "username" {
#   description = "PVE API username"
#   type        = string
# }

# variable "password" {
#   description = "PVE API password"
#   type        = string
#   sensitive   = true
# }

variable "host_public_key" {
  description = "Host public key"
  type        = string
}

variable "cilium_cli_version" {
  description = "Cilium CLI version"
  type        = string
}
