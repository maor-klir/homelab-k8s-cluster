
locals {
  buildtime = formatdate("YYYY-MM-DD hh:mm ZZZ", timestamp())
}

source "proxmox-clone" "ubuntu-2404" {

  clone_vm_id = "7000"

  # Proxmox Connection Settings
  proxmox_url = var.proxmox_url
  node       = var.proxmox_node
  username    = var.proxmox_username
  # token                    = var.proxmox__api_token
  password                 = var.proxmox_password
  insecure_skip_tls_verify = true

  # VM General Settings
  vm_id                = var.vm_id
  vm_name              = "ubuntu-2404-template"
  template_description = "Ubuntu 24.04 Server Template, built with Packer on ${local.buildtime}"

  # Explicitly set boot order to prefer scsi0 (installed disk) over ide devices
  boot = "order=scsi0;net0;ide0"

  # VM System Settings
  qemu_agent = true
  sockets    = "1"
  cpu_type   = "host"
  cores      = "2"
  memory     = "2048"
  os         = "l26"
  machine    = "q35"


  # VM Hard Disk Settings
  scsi_controller = "virtio-scsi-single"
  disks {
    disk_size    = "20G"
    format       = "qcow2"
    storage_pool = "local-zfs"
    type         = "scsi"
    ssd          = true
  }

  # VM Network Settings
  network_adapters {
    model  = "virtio"
    bridge = "vmbr0"
  }

  # VM Cloud-Init Settings
  cloud_init              = true
  cloud_init_storage_pool = "local-lvm"

  # Cloud-init config via additional ISO
  # additional_iso_files {
  #   type              = "ide"
  #   index             = 1
  #   iso_storage_pool  = "local"
  #   unmount           = true
  #   keep_cdrom_device = false
  #   cd_files = [
  #     "./http/meta-data",
  #     "./http/user-data"
  #   ]
  #   cd_label = "cidata"
  # }

  # Communicator Settings
  ssh_username = var.ssh_username
  ssh_timeout  = "30m"
}
