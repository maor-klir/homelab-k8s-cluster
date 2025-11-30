resource "proxmox_virtual_environment_vm" "k3s-cp-01" {
  name        = "k3s-cp-01"
  description = "K3s control plane node 01"
  tags        = ["k3s", "control-plane"]
  node_name   = var.pve_node_name.node_01
  vm_id       = "101"
  on_boot     = true

  started       = true
  machine       = "q35"
  scsi_hardware = "virtio-scsi-single"
  bios          = "ovmf"

  # clone {
  #   vm_id = data.proxmox_virtual_environment_vm.k3s-ubuntu-template.vm_id
  # }

  agent {
    enabled = false
  }

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 16384
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
        address = "192.168.0.201/24"
        gateway = "192.168.0.1"
      }
    }
    user_account {
      username = var.k3s_vm_user
      keys     = [var.k3s_public_key]
    }
  }
}

resource "proxmox_virtual_environment_vm" "k3s-worker-01" {
  name        = "k3s-worker-01"
  description = "K3s worker node 01"
  tags        = ["k3s", "worker"]
  node_name   = var.pve_node_name.node_02
  vm_id       = "102"
  on_boot     = true

  started       = true
  machine       = "q35"
  scsi_hardware = "virtio-scsi-single"
  bios          = "ovmf"

  # clone {
  #   vm_id = data.proxmox_virtual_environment_vm.k3s-ubuntu-template.vm_id
  # }

  agent {
    enabled = false
  }

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 8192
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
        address = "192.168.0.202/24"
        gateway = "192.168.0.1"
      }
    }
    user_account {
      username = var.k3s_vm_user
      keys     = [var.k3s_public_key]
    }
  }
}

resource "proxmox_virtual_environment_vm" "k3s-worker-02" {
  name        = "k3s-worker-02"
  description = "K3s worker node 02"
  tags        = ["k3s", "worker"]
  node_name   = var.pve_node_name.node_03
  vm_id       = "103"
  on_boot     = true

  started       = true
  machine       = "q35"
  scsi_hardware = "virtio-scsi-single"
  bios          = "ovmf"

  # clone {
  #   vm_id = data.proxmox_virtual_environment_vm.k3s-ubuntu-template.vm_id
  # }

  agent {
    enabled = false
  }

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 8192
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
        address = "192.168.0.203/24"
        gateway = "192.168.0.1"
      }
    }
    user_account {
      username = var.k3s_vm_user
      keys     = [var.k3s_public_key]
    }
  }
}
