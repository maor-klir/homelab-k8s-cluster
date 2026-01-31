# Proxmox VE K3s VM configuration variables
control_plane_count = 3
worker_count        = 3
k3s_vm_user         = "k3s"
k3s_vm_dns = {
  domain  = ".local"
  servers = ["1.1.1.1", "8.8.8.8"]
}

# Azure - HCP Terraform integration input variables
azure_subscription_id = "f434d9a5-438f-413f-bba0-243d0fbad167"

# Azure workload identity variables
oidc_rg                        = "oidc-issuer-prod"
oidc_rg_location               = "West Europe"
oidc_storage_account           = "oidcissuerk3sprod122025"
oidc_storage_container         = "$web"
azwi_rg                        = "azwi-prod"
azwi_rg_location               = "West Europe"
akv_azwi_name                  = "azwi-kv-k3s-prod-122025"
akv_azwi_location              = "West Europe"
azwi_service_account_name      = "workload-identity-sa"
azwi_service_account_namespace = "external-secrets-operator"

# Azure variables for Thanos
thanos_storage_account_name = "thanosak3sprod012026"
thanos_rg                   = "observability-proxmox-k3s"
