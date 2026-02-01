output "oidc_issuer_uri" {
  description = "The OIDC issuer URI"
  value       = local.oidc_issuer_uri
}

output "key_vault_id" {
  description = "The ID of the Azure Key Vault"
  value       = azurerm_key_vault.akv_azwi.id
}

output "key_vault_name" {
  description = "The name of the Azure Key Vault"
  value       = azurerm_key_vault.akv_azwi.name
}

output "service_principal_client_id" {
  description = "The client ID of the Azure AD service principal"
  value       = azuread_service_principal.azwi_service_principal.client_id
}

output "service_principal_object_id" {
  description = "The object ID of the Azure AD service principal"
  value       = azuread_service_principal.azwi_service_principal.object_id
}

output "application_id" {
  description = "The application ID"
  value       = azuread_application.azwi_application.client_id
}

output "application_object_id" {
  description = "The application object ID (used for federated credentials)"
  value       = azuread_application.azwi_application.object_id
}

output "resource_group_name" {
  description = "The name of the Azure Workload Identity resource group"
  value       = azurerm_resource_group.azwi_rg.name
}
