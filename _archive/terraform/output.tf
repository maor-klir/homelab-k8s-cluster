# output "vm_ipv4_address" {
#   value = proxmox_virtual_environment_vm.ubuntu_clone.ipv4_addresses[1][0]
# }

# Outputs for environment-specific federated credentials
output "hcpt_application_id" {
  value       = azuread_application.hcpt_application.id
  description = "HCP Terraform application ID for creating environment-specific federated credentials"
}

output "hcpt_service_principal_client_id" {
  value       = azuread_service_principal.hcpt_service_principal.client_id
  description = "HCP Terraform service principal client ID - shared across all workspaces via a variable set"
}

output "hcpt_service_principal_object_id" {
  value       = azuread_service_principal.hcpt_service_principal.object_id
  description = "HCP Terraform service principal object ID"
}
