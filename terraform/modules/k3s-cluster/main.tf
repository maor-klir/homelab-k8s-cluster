locals {
  # Create a map of all nodes with their properties
  nodes = merge(
    # Control plane nodes
    {
      for i in range(var.control_plane_count) :
      "cp-${format("%02d", i + 1)}" => {
        name        = "k3s-${var.environment}-cp-${format("%02d", i + 1)}"
        description = "K3s ${var.environment} control plane node ${format("%02d", i + 1)}"
        tags        = ["k3s", "control-plane", var.environment]
        node_name   = var.pve_nodes[i % length(var.pve_nodes)]
        vm_id       = var.vm_id_start + i
        ip_address  = "${var.base_ip_address}${var.vm_id_start + i}"
        memory      = var.control_plane_memory
        cores       = var.control_plane_cores
      }
    },
    # Worker nodes
    {
      for i in range(var.worker_count) :
      "worker-${format("%02d", i + 1)}" => {
        name        = "k3s-${var.environment}-worker-${format("%02d", i + 1)}"
        description = "K3s ${var.environment} worker node ${format("%02d", i + 1)}"
        tags        = ["k3s", "worker", var.environment]
        node_name   = var.pve_nodes[(var.control_plane_count + i) % length(var.pve_nodes)]
        vm_id       = var.vm_id_start + var.control_plane_count + i
        ip_address  = "${var.base_ip_address}${var.vm_id_start + var.control_plane_count + i}"
        memory      = var.worker_memory
        cores       = var.worker_cores
      }
    }
  )
}

resource "proxmox_virtual_environment_vm" "k3s_nodes" {
  for_each = local.nodes

  name        = each.value.name
  description = each.value.description
  tags        = each.value.tags
  node_name   = each.value.node_name
  vm_id       = each.value.vm_id
  on_boot     = true

  started       = true
  machine       = "q35"
  scsi_hardware = "virtio-scsi-single"
  bios          = "ovmf"

  clone {
    vm_id = data.proxmox_virtual_environment_vm.k3s-ubuntu-template.vm_id
  }

  agent {
    enabled = false
  }

  cpu {
    cores = each.value.cores
    type  = "host"
  }

  memory {
    dedicated = each.value.memory
  }

  operating_system {
    type = "l26"
  }

  efi_disk {
    type              = "4m"
    pre_enrolled_keys = true
  }

  initialization {
    dns {
      domain  = var.k3s_vm_dns.domain
      servers = var.k3s_vm_dns.servers
    }
    ip_config {
      ipv4 {
        address = "${each.value.ip_address}/${var.subnet_mask}"
        gateway = var.gateway
      }
    }
    user_account {
      username = var.k3s_vm_user
      keys     = [var.k3s_public_key]
    }
  }
}
