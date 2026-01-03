# K3s cluster module outputs
#
output "k3s_nodes" {
  value = module.k3s_cluster.k3s_nodes
}
# Azure Workload Identity module outputs
#
output "oidc_issuer_uri" {
  description = "The OIDC issuer URI"
  value       = module.azure_workload_identity.oidc_issuer_uri
}

output "key_vault_id" {
  description = "The ID of the Azure Key Vault"
  value       = module.azure_workload_identity.key_vault_id
}

output "key_vault_name" {
  description = "The name of the Azure Key Vault"
  value       = module.azure_workload_identity.key_vault_name
}

output "service_principal_client_id" {
  description = "The client ID of the Azure AD service principal"
  value       = module.azure_workload_identity.service_principal_client_id
}

output "service_principal_object_id" {
  description = "The object ID of the Azure AD service principal"
  value       = module.azure_workload_identity.service_principal_object_id
}

output "application_id" {
  description = "The application ID"
  value       = module.azure_workload_identity.application_id
}
