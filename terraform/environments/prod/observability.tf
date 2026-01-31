# Thanos Storage Account creation using Azure Verified Module
# https://github.com/Azure/terraform-azurerm-avm-res-storage-storageaccount
module "thanos_storage" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "~> 0.6.0"

  name                     = var.thanos_storage_account_name
  resource_group_name      = module.azure_workload_identity.resource_group_name
  location                 = var.azwi_rg_location
  account_tier             = "Standard"
  account_replication_type = "ZRS" # Zone-redundant for high availability
  account_kind             = "StorageV2"

  blob_properties = {
    delete_retention_policy = {
      days = 90
    }
    versioning_enabled = true
  }

  network_rules = {
    default_action             = "Allow"
    bypass                     = ["AzureServices"]
    ip_rules                   = []
    virtual_network_subnet_ids = []
  }

  tags = {
    Environment = "prod"
    ManagedBy   = "Terraform"
    Purpose     = "Observability"
    Component   = "Thanos"
    Project     = "proxmox-k3s"
  }
}

resource "azurerm_storage_container" "thanos_metrics" {
  name                  = "metrics"
  storage_account_id    = module.thanos_storage.resource_id
  container_access_type = "private"
}

# RBAC - Storage Blob Data Contributor for Azure Workload Identity
resource "azurerm_role_assignment" "storage_blob_data_contributor" {
  scope                = module.thanos_storage.resource_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.azure_workload_identity.service_principal_object_id
}
