locals {
  load_balancer = {
    for i in range(var.lxc_lb_count) :
    "lb-${format("%02d", i + 1)}" => {
      name        = "k3s-prod-lb-${format("%02d", i + 1)}"
      description = "K3s prod cluster load balancer ${format("%02d", i + 1)}"
      tags        = ["k3s", "cluster-load-balancer", "prod"]
      node_name   = var.pve_node_name[i % length(var.pve_node_name)]
      vm_id       = var.lxc_lb_id_start + i
      ip_address  = "${var.base_ip_address}${var.lxc_lb_id_start + i}"
      memory      = var.lxc_lb_memory
      cores       = var.lxc_lb_cores
    }
  }
}

resource "proxmox_virtual_environment_container" "lxc_lb" {
  for_each = local.load_balancer

  description   = each.value.description
  tags          = each.value.tags
  node_name     = each.value.node_name
  vm_id         = each.value.vm_id
  start_on_boot = true

  unprivileged = true
  features {
    nesting = true
  }

  cpu {
    cores = var.lxc_lb_cores
  }

  memory {
    dedicated = var.lxc_lb_memory
    swap      = "512"
  }

  network_interface {
    name = "eth0"
  }

  disk {
    datastore_id = "local"
    size         = 4
  }

  operating_system {
    template_file_id = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
    type             = "ubuntu"
  }

  initialization {
    hostname = each.value.name
    ip_config {
      ipv4 {
        address = "${each.value.ip_address}/${var.lxc_subnet_mask}"
        gateway = var.lxc_gateway
      }
    }
    user_account {
      keys = [
        trimspace(tls_private_key.lxc_container_key.public_key_openssh)
      ]
    }
  }
}

resource "tls_private_key" "lxc_container_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

output "lxc_container_private_key" {
  value     = tls_private_key.lxc_container_key.private_key_pem
  sensitive = true
}

output "lxc_container_public_key" {
  value = tls_private_key.lxc_container_key.public_key_openssh
}
