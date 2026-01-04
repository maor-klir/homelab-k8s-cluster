locals {
  # Get the first control plane IP address
  control_plane_ip = "${var.base_ip_address}${var.vm_id_start}"

  # Create a map of all nodes with their properties
  nodes = merge(
    # Control plane nodes
    {
      for i in range(var.control_plane_count) :
      "cp-${format("%02d", i + 1)}" => {
        name        = "k3s-${var.environment}-cp-${format("%02d", i + 1)}"
        description = "K3s ${var.environment} control plane node ${format("%02d", i + 1)}"
        tags        = ["k3s", "control-plane", var.environment]
        role        = "control-plane"
        node_name   = var.pve_node_name[i % length(var.pve_node_name)]
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
        role        = "worker"
        node_name   = var.pve_node_name[(var.control_plane_count + i) % length(var.pve_node_name)]
        vm_id       = var.vm_id_start + var.control_plane_count + i
        ip_address  = "${var.base_ip_address}${var.vm_id_start + var.control_plane_count + i}"
        memory      = var.worker_memory
        cores       = var.worker_cores
      }
    }
  )
}

# Upload cloud-init snippets to Proxmox (one per VM)
resource "proxmox_virtual_environment_file" "user_data" {
  for_each = local.nodes

  content_type = "snippets"
  datastore_id = "local"
  node_name    = each.value.node_name

  source_raw {
    file_name = "user-data-${each.value.name}.yaml"
    data = templatefile(
      each.value.role == "control-plane" ? "${path.module}/${var.user_data_control_plane}" : "${path.module}/${var.user_data_worker}",
      each.value.role == "control-plane" ? {
        general_config = templatefile("${path.module}/${var.user_data_general}", {
          username   = var.k3s_vm_user
          public_key = var.k3s_public_key
          hostname   = each.value.name
        })
        k3s_config = templatefile("${path.module}/k3s-config/config.yaml.tftpl", {
          k3s_token        = var.k3s_token
          control_plane_ip = local.control_plane_ip
          oidc_issuer_uri  = var.oidc_issuer_uri
        })
        k3s_script             = templatefile("${path.module}/scripts/k3s.sh", {})
        wait_for_k3s_script    = templatefile("${path.module}/scripts/wait-for-k3s.sh", {})
        cilium_script          = templatefile("${path.module}/scripts/cilium.sh", {}) # Using templatefile() for consistency, even though cilium.sh currently has no template variables
        workload_identity_keys = file("${path.module}/scripts/workload-identity-keys.sh")
        cilium_values = templatefile("${path.module}/helm/cilium-values.yaml.tftpl", {
          k8sServiceHost = local.control_plane_ip
        })
        } : {
        general_config = templatefile("${path.module}/${var.user_data_general}", {
          username   = var.k3s_vm_user
          public_key = var.k3s_public_key
          hostname   = each.value.name
        })
        k3s_token        = var.k3s_token
        control_plane_ip = local.control_plane_ip
        k3s_cluster_port = var.k3s_cluster_port
      }
    )
  }
}

# Provision K3s VMs in Proxmox VE
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

  agent {
    enabled = true
    timeout = "3m" # Reduce from default 15m
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

  network_device {
    bridge = "vmbr0"
  }

  efi_disk {
    type              = "4m" # Modern 4MB OVMF (UEFI) firmware, required for Secure Boot support (vs 2m legacy version)
    pre_enrolled_keys = true # Automatically enrolls Microsoft and distribution Secure Boot keys so the OS can boot
  }

  disk {
    datastore_id = "local-lvm"
    file_id      = "local:import/noble-server-cloudimg-amd64.qcow2"
    interface    = "scsi0"
    iothread     = true
    cache        = "writeback"
    discard      = "on"
    ssd          = true
    size         = 32 # Size in GiB (Proxmox disk size is specified in GiB)
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
    user_data_file_id = proxmox_virtual_environment_file.user_data[each.key].id
  }

  # cloud-init runs once on first boot - ignore user-data changes to prevent unnecessary VM replacements
  lifecycle {
    ignore_changes = [
      initialization[0].user_data_file_id
    ]
  }
}
