output "k3s_nodes" {
  description = "Map of all node details"
  value = {
    for k, v in proxmox_virtual_environment_vm.k3s_nodes :
    k => {
      name       = v.name
      role       = contains(v.tags, "control-plane") ? "control-plane" : "worker"
      ip_address = v.initialization[0].ip_config[0].ipv4[0].address
    }
  }
}

output "workload_identity_public_key_pem" {
  description = "Workload identity service account public key in PEM format for JWKS generation"
  value       = tls_private_key.workload_identity_sa.public_key_pem
  sensitive   = false
}
