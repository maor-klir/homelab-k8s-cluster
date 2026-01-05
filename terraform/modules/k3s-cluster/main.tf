# Generate a TLS private key for workload identity service account
resource "tls_private_key" "workload_identity_sa" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

locals {
  # Get the first control plane IP address
  control_plane_ip = "${var.base_ip_address}${var.vm_id_start}"

  # Control plane nodes
  control_plane_nodes = {
    for i in range(var.control_plane_count) :
    "cp-${format("%02d", i + 1)}" => {
      name        = "k3s-${var.environment}-cp-${format("%02d", i + 1)}"
      description = "K3s ${var.environment} control plane node ${format("%02d", i + 1)}"
      tags        = ["k3s", "control-plane", var.environment]
      node_name   = var.pve_node_name[i % length(var.pve_node_name)]
      vm_id       = var.vm_id_start + i
      ip_address  = "${var.base_ip_address}${var.vm_id_start + i}"
      memory      = var.control_plane_memory
      cores       = var.control_plane_cores
    }
  }

  # Worker nodes
  worker_nodes = {
    for i in range(var.worker_count) :
    "worker-${format("%02d", i + 1)}" => {
      name        = "k3s-${var.environment}-worker-${format("%02d", i + 1)}"
      description = "K3s ${var.environment} worker node ${format("%02d", i + 1)}"
      tags        = ["k3s", "worker", var.environment]
      node_name   = var.pve_node_name[(var.control_plane_count + i) % length(var.pve_node_name)]
      vm_id       = var.vm_id_start + var.control_plane_count + i
      ip_address  = "${var.base_ip_address}${var.vm_id_start + var.control_plane_count + i}"
      memory      = var.worker_memory
      cores       = var.worker_cores
    }
  }
}

# Upload cloud-init snippets for control plane nodes
resource "proxmox_virtual_environment_file" "cp_user_data" {
  for_each = local.control_plane_nodes

  content_type = "snippets"
  datastore_id = "local"
  node_name    = each.value.node_name

  source_raw {
    file_name = "user-data-${each.value.name}.yaml"
    data = templatefile("${path.module}/${var.user_data_control_plane}", {
      general_config = templatefile("${path.module}/${var.user_data_general}", {
        username   = var.k3s_vm_user
        public_key = var.k3s_public_key
        hostname   = each.value.name
      })
      k3s_config = templatefile("${path.module}/k3s-config/config.yaml.tftpl", {
        control_plane_ip = local.control_plane_ip
        oidc_issuer_uri  = var.oidc_issuer_uri
      })
      k3s_script          = templatefile("${path.module}/scripts/k3s.sh", {})
      wait_for_k3s_script = templatefile("${path.module}/scripts/wait-for-k3s.sh", {})
      cilium_script       = templatefile("${path.module}/scripts/cilium.sh", {})
      # Inject the same workload identity keys to all control plane nodes in the cluster
      workload_identity_private_key = tls_private_key.workload_identity_sa.private_key_pem
      workload_identity_public_key  = tls_private_key.workload_identity_sa.public_key_pem
      cilium_values = templatefile("${path.module}/helm/cilium-values.yaml.tftpl", {
        k8sServiceHost = local.control_plane_ip
      })
    })
  }
}

# Upload cloud-init snippets for worker nodes (depends on token being fetched)
resource "proxmox_virtual_environment_file" "worker_user_data" {
  for_each = local.worker_nodes

  # Ensure this is created after the token is fetched
  depends_on = [data.external.k3s_token]

  content_type = "snippets"
  datastore_id = "local"
  node_name    = each.value.node_name

  source_raw {
    file_name = "user-data-${each.value.name}.yaml"
    data = templatefile("${path.module}/${var.user_data_worker}", {
      general_config = templatefile("${path.module}/${var.user_data_general}", {
        username   = var.k3s_vm_user
        public_key = var.k3s_public_key
        hostname   = each.value.name
      })
      k3s_token        = data.external.k3s_token.result.token
      control_plane_ip = local.control_plane_ip
      k3s_cluster_port = var.k3s_cluster_port
    })
  }
}

# Provision control plane VMs in Proxmox VE
resource "proxmox_virtual_environment_vm" "control_plane" {
  for_each = local.control_plane_nodes

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
    user_data_file_id = proxmox_virtual_environment_file.cp_user_data[each.key].id
  }

  # cloud-init runs once on first boot - ignore user-data changes to prevent unnecessary VM replacements
  lifecycle {
    ignore_changes = [
      initialization[0].user_data_file_id
    ]
  }
}

# Provision worker VMs in Proxmox VE (after token is fetched)
resource "proxmox_virtual_environment_vm" "workers" {
  for_each = local.worker_nodes

  # Ensure workers are created after control plane and token fetch
  depends_on = [data.external.k3s_token]

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
    user_data_file_id = proxmox_virtual_environment_file.worker_user_data[each.key].id
  }

  # cloud-init runs once on first boot - ignore user-data changes to prevent unnecessary VM replacements
  lifecycle {
    ignore_changes = [
      initialization[0].user_data_file_id
    ]
  }
}

# Fetch the native k3s token from the first control plane node
resource "terraform_data" "fetch_k3s_token" {
  # Only run this after the first control plane node is created and initialized
  depends_on = [proxmox_virtual_environment_vm.control_plane]

  # Re-run if the first control plane VM is recreated
  triggers_replace = [
    proxmox_virtual_environment_vm.control_plane["cp-01"].id
  ]

  provisioner "local-exec" {
    command = <<-EOT
      max_attempts=60
      attempt=0
      while [ $attempt -lt $max_attempts ]; do
        if ssh -i <(echo "${base64decode(var.private_ssh_key)}") \
            -o StrictHostKeyChecking=no \
            -o UserKnownHostsFile=/dev/null \
            -o ConnectTimeout=5 \
            ${var.k3s_vm_user}@${local.control_plane_ip} \
            "test -f /var/lib/rancher/k3s/server/token" 2>/dev/null; then
          echo "K3s token file found"
          exit 0
        fi
        attempt=$((attempt + 1))
        sleep 5
      done
      echo "Timeout waiting for k3s token file"
      exit 1
    EOT
  }
}

# Use external data source to capture the token
data "external" "k3s_token" {
  depends_on = [terraform_data.fetch_k3s_token]

  program = ["bash", "-c", <<-EOT
    ssh -i <(echo "${base64decode(var.private_ssh_key)}") \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        ${var.k3s_vm_user}@${local.control_plane_ip} \
        "jq -n --arg token \\"\\$(cat /var/lib/rancher/k3s/server/token)\\" '{token: \\$token}'"
  EOT
  ]
}
