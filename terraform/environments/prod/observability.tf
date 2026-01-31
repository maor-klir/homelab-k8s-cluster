resource "azurerm_storage_account" "thanos_storage_account" {
  name                            = var.thanos_storage_account_name
  resource_group_name             = var.thanos_rg
  location                        = var.azwi_rg_location
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
  network_rules {
    default_action             = "Allow"
    bypass                     = ["AzureServices"]
    ip_rules                   = []
    virtual_network_subnet_ids = []
  }

}

resource "azurerm_storage_container" "thanos_metrics" {
  name                  = "metrics"
  storage_account_id    = azurerm_storage_account.thanos_storage_account.id
  container_access_type = "private"
}

# RBAC - Storage Blob Data Contributor for Azure Workload Identity
resource "azurerm_role_assignment" "storage_blob_data_contributor" {
  scope                = azurerm_storage_account.thanos_storage_account.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.azure_workload_identity.service_principal_object_id
}
