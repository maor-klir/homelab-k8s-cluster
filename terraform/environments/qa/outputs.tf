output "k3s_cluster" {
  description = "K3s cluster node information"
  value = {
    control_plane_nodes = module.k3s_cluster.control_plane_nodes
    worker_nodes        = module.k3s_cluster.worker_nodes
    all_nodes           = module.k3s_cluster.all_nodes
  }
}

output "azure_workload_identity" {
  description = "Azure Workload Identity information"
  value = {
    oidc_issuer_uri             = module.azure_workload_identity.oidc_issuer_uri
    key_vault_name              = module.azure_workload_identity.key_vault_name
    service_principal_client_id = module.azure_workload_identity.service_principal_client_id
  }
}
