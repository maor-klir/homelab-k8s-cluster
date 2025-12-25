output "control_plane_nodes" {
  description = "Map of control plane node details"
  value = {
    for k, v in proxmox_virtual_environment_vm.k3s_nodes :
    k => {
      name       = v.name
      vm_id      = v.vm_id
      ip_address = v.initialization[0].ip_config[0].ipv4[0].address
    }
    if contains(v.tags, "control-plane")
  }
}

output "worker_nodes" {
  description = "Map of worker node details"
  value = {
    for k, v in proxmox_virtual_environment_vm.k3s_nodes :
    k => {
      name       = v.name
      vm_id      = v.vm_id
      ip_address = v.initialization[0].ip_config[0].ipv4[0].address
    }
    if contains(v.tags, "worker")
  }
}
