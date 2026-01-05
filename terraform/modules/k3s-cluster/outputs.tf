output "k3s_nodes" {
  description = "Map of all node details"
  value = merge(
    {
      for k, v in proxmox_virtual_environment_vm.control_plane :
      k => {
        name       = v.name
        role       = "control-plane"
        ip_address = v.initialization[0].ip_config[0].ipv4[0].address
      }
    },
    {
      for k, v in proxmox_virtual_environment_vm.workers :
      k => {
        name       = v.name
        role       = "worker"
        ip_address = v.initialization[0].ip_config[0].ipv4[0].address
      }
    }
  )
}

output "workload_identity_public_key_pem" {
  description = "Workload identity service account public key in PEM format for JWKS generation"
  value       = tls_private_key.workload_identity_sa.public_key_pem
  sensitive   = false
}
