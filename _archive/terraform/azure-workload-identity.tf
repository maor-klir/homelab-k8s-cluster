##############################
### OpenID Connect Issuer ###
##############################

resource "azurerm_resource_group" "oidc-rg" {
  name     = var.oidc_rg
  location = var.oidc_rg_location
}

resource "azurerm_storage_account" "oidc-storage-account" {
  name                            = var.oidc_storage_account
  resource_group_name             = azurerm_resource_group.oidc-rg.name
  location                        = azurerm_resource_group.oidc-rg.location
  account_tier                    = "Standard"
  account_replication_type        = "RAGRS"
  allow_nested_items_to_be_public = true
}

#trivy:ignore:AVD-AZU-0007 Public access required for OIDC issuer - Entra ID must fetch /.well-known/openid-configuration
resource "azurerm_storage_container" "oidc_storage_container" {
  container_access_type = "blob"
  name                  = var.oidc_storage_container
  storage_account_id    = azurerm_storage_account.oidc-storage-account.id
}

locals {
  # The base URI for the OIDC issuer
  oidc_issuer_uri = "https://${azurerm_storage_account.oidc-storage-account.name}.blob.core.windows.net/${azurerm_storage_container.oidc_storage_container.name}"

  # Holds the content of the openid-configuration.json file
  openid_configuration_content = jsonencode({
    issuer                                = local.oidc_issuer_uri
    jwks_uri                              = "${local.oidc_issuer_uri}/openid/v1/jwks"
    response_types_supported              = ["id_token"]
    subject_types_supported               = ["public"]
    id_token_signing_alg_values_supported = ["RS256"]
  })
}

resource "azurerm_storage_blob" "openid_configuration" {
  name                   = ".well-known/openid-configuration"
  storage_account_name   = azurerm_storage_account.oidc-storage-account.name
  storage_container_name = azurerm_storage_container.oidc_storage_container.name
  type                   = "Block" # Required for content-based uploads
  source_content         = local.openid_configuration_content
  content_type           = "application/json" # Set the correct MIME type
}

################################
### JSON Web Key Sets (JWKS) ###
################################

# JWKS file - pre-generated using: azwi jwks --public-keys <key_path> --output-file jwks.json
data "local_file" "jwks" {
  filename = "${path.module}/jwks/jwks.json"
}

resource "azurerm_storage_blob" "jwks_document" {
  name                   = "openid/v1/jwks"
  storage_account_name   = azurerm_storage_account.oidc-storage-account.name
  storage_container_name = azurerm_storage_container.oidc_storage_container.name
  type                   = "Block"
  source_content         = data.local_file.jwks.content
  content_type           = "application/jwk-set+json"
}

############################################################################################################
### Set up Azure Workload Identity to acquire an Entra ID token to access a secret in an Azure Key Vault ###
############################################################################################################

resource "azurerm_resource_group" "azwi_rg" {
  name     = var.azwi_rg
  location = var.azwi_rg_location
}

#trivy:ignore:AVD-AZU-0013 Key Vault accessed only via Azure Workload Identity
#trivy:ignore:AVD-AZU-0016 Purge protection not needed for dev/test environment
resource "azurerm_key_vault" "akv_azwi" {
  name                       = var.akv_azwi_name
  location                   = var.akv_azwi_location
  resource_group_name        = azurerm_resource_group.azwi_rg.name
  tenant_id                  = data.azuread_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  soft_delete_retention_days = 90
}

resource "azuread_application" "azwi_application" {
  display_name = "azwi"
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "azwi_service_principal" {
  client_id = azuread_application.azwi_application.client_id
}

resource "azurerm_role_assignment" "azwi_kv_secrets_user_role_assignment" {
  scope                            = azurerm_key_vault.akv_azwi.id
  principal_id                     = azuread_service_principal.azwi_service_principal.object_id
  role_definition_name             = "Key Vault Secrets User"
  skip_service_principal_aad_check = true
}

# Federated identity credential - allows Kubernetes service account to authenticate as this Azure identity
resource "azuread_application_federated_identity_credential" "azwi_federated_credential" {
  application_id = "/applications/${azuread_application.azwi_application.object_id}"
  display_name   = "kubernetes-federated-credential"
  description    = "Kubernetes service account federated credential"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = local.oidc_issuer_uri
  subject        = "system:serviceaccount:${var.azwi_service_account_namespace}:${var.azwi_service_account_name}"
  depends_on     = [azuread_application.azwi_application]
}
