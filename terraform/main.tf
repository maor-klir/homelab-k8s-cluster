resource "proxmox_virtual_environment_vm" "k3s-cp-01" {
  provider  = proxmox
  node_name = "pve-02"

  name        = "k3s-cp-01"
  description = "K3s-cp-01"
  tags        = ["k3s", "control-plane"]
  on_boot     = true
  vm_id       = 1001

  machine       = "q35"
  scsi_hardware = "virtio-scsi-single"
  bios          = "ovmf"


  cpu {
    cores = 2
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 4096
  }

  network_device {
    bridge = "vmbr0"
  }

  efi_disk {
    datastore_id = "local-zfs"
    file_format  = "raw" // To support qcow2 format
    type         = "4m"
  }

  disk {
    datastore_id = "local-zfs"
    file_id      = proxmox_virtual_environment_download_file.ubuntu.id
    interface    = "scsi0"
    cache        = "writethrough"
    discard      = "on"
    ssd          = true
    size         = 32
  }

  boot_order = ["scsi0"]

  # Enable QEMU guest agent
  agent {
    enabled = true
  }

  operating_system {
    type = "l26" # Linux Kernel 2.6 - 6.X.
  }

  initialization {
    meta_data_file_id = proxmox_virtual_environment_file.pve-cp.id
    datastore_id      = "local-zfs"
    ip_config {
      ipv4 {
        address = "192.168.1.151/24"
        gateway = "192.168.0.1"
      }
    }
  }
}

# output "k3s-cp-01-ipv4" {
#   depends_on = [proxmox_virtual_environment_vm.k3s-cp-01]
#   value      = proxmox_virtual_environment_vm.k3s-cp-01.ipv4_addresses[1][0]
# }

# resource "local_file" "k3s-cp-01-ipv4" {
#   content         = proxmox_virtual_environment_vm.k3s-cp-01.ipv4_addresses[1][0]
#   filename        = "output/k3s-cp-01-ipv4.txt"
#   file_permission = "0644"
# }

# module "kube-config" {
#   depends_on   = [local_file.k3s-cp-01-ipv4]
#   source       = "Invicton-Labs/shell-resource/external"
#   version      = "0.4.1"
#   command_unix = "ssh -o StrictHostKeyChecking=no ${var.vm_username}@${local_file.k3s-cp-01-ipv4.content} cat /home/${var.vm_username}/.kube/config"
# }

# resource "local_file" "kube-config" {
#   content         = module.kube-config.stdout
#   filename        = "output/config"
#   file_permission = "0600"
# }

# module "kubeadm-join" {
#   depends_on   = [local_file.kube-config]
#   source       = "Invicton-Labs/shell-resource/external"
#   version      = "0.4.1"
#   command_unix = "ssh -o StrictHostKeyChecking=no ${var.vm_username}@${local_file.k3s-ctrl-01-ipv4.content} /usr/bin/kubeadm token create --print-join-command"
# }
