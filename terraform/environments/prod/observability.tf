#############################
### Thanos implementation ###
#############################

resource "azurerm_resource_group" "observability_rg" {
  name     = var.observability_rg
  location = var.azwi_rg_location
}

moved {
  from = azurerm_resource_group.thanos_rg
  to   = azurerm_resource_group.observability_rg
}

resource "azurerm_storage_account" "thanos_storage_account" {
  name                            = var.thanos_storage_account_name
  resource_group_name             = azurerm_resource_group.observability_rg.name
  location                        = azurerm_resource_group.observability_rg.location
  account_tier                    = "Standard"
  account_kind                    = "StorageV2"
  account_replication_type        = "ZRS"
  allow_nested_items_to_be_public = false

  blob_properties {
    delete_retention_policy {
      days = 90
    }
    versioning_enabled = true
  }
}

resource "azurerm_storage_container" "thanos_metrics" {
  name                  = "metrics"
  storage_account_id    = azurerm_storage_account.thanos_storage_account.id
  container_access_type = "private"
}

# RBAC - Storage Blob Data Contributor for Azure Workload Identity
resource "azurerm_role_assignment" "thanos_storage_blob_data_contributor" {
  scope                = azurerm_storage_account.thanos_storage_account.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.azure_workload_identity.service_principal_object_id
}

moved {
  from = azurerm_role_assignment.storage_blob_data_contributor
  to   = azurerm_role_assignment.thanos_storage_blob_data_contributor
}

###########################
### Loki implementation ###
###########################

resource "azurerm_storage_account" "loki_storage_account" {
  name                            = var.loki_storage_account_name
  resource_group_name             = azurerm_resource_group.observability_rg.name
  location                        = azurerm_resource_group.observability_rg.location
  account_tier                    = "Standard"
  account_kind                    = "StorageV2"
  account_replication_type        = "ZRS"
  allow_nested_items_to_be_public = false

  blob_properties {
    delete_retention_policy {
      days = 90
    }
    versioning_enabled = true
  }
}

resource "azurerm_storage_container" "loki_logs" {
  name                  = "logs"
  storage_account_id    = azurerm_storage_account.loki_storage_account.id
  container_access_type = "private"
}

# RBAC - Storage Blob Data Contributor for Azure Workload Identity
resource "azurerm_role_assignment" "loki_storage_blob_data_contributor" {
  scope                = azurerm_storage_account.loki_storage_account.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.azure_workload_identity.service_principal_object_id
}
