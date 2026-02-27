locals {
  # Construct the OIDC issuer URI - must match what azure_workload_identity module creates
  oidc_issuer_uri = "https://${var.oidc_storage_account}.blob.core.windows.net/${var.oidc_storage_container}"
}

module "k3s_cluster" {
  source  = "app.terraform.io/maor/terraform-proxmox-k3s-cluster/proxmox"
  version = "1.1.1"

  pve_node_name       = var.pve_node_name
  private_ssh_key     = var.private_ssh_key
  environment         = "prod"
  control_plane_count = var.control_plane_count
  worker_count        = var.worker_count

  base_ip_address = var.base_ip_address
  vm_id_start     = 201

  k3s_token      = var.k3s_token
  k3s_public_key = var.k3s_public_key
  k3s_vm_dns     = var.k3s_vm_dns
  k3s_vm_user    = var.k3s_vm_user

  # OIDC issuer URI for Azure Workload Identity
  oidc_issuer_uri = local.oidc_issuer_uri

  # Being explicit only for clarity (all have default values in the module)
  control_plane_memory = 8192
  control_plane_cores  = 2
  worker_memory        = 8192
  worker_cores         = 2
  gateway              = "192.168.0.1"
  subnet_mask          = "24"
}

module "azure_workload_identity" {
  source  = "app.terraform.io/maor/terraform-azure-workload-identity-federation-k8s/azure"
  version = "0.2.3"

  environment            = "prod"
  azure_subscription_id  = var.azure_subscription_id
  oidc_rg                = var.oidc_rg
  oidc_rg_location       = var.oidc_rg_location
  oidc_storage_account   = var.oidc_storage_account
  oidc_storage_container = var.oidc_storage_container

  azwi_rg           = var.azwi_rg
  azwi_rg_location  = var.azwi_rg_location
  akv_azwi_name     = var.akv_azwi_name
  akv_azwi_location = var.akv_azwi_location

  azwi_service_account_namespace = var.azwi_service_account_namespace
  azwi_service_account_name      = var.azwi_service_account_name

  # Pass the public key from k3s_cluster module for JWKS generation
  workload_identity_public_key_pem = module.k3s_cluster.workload_identity_public_key_pem
}
