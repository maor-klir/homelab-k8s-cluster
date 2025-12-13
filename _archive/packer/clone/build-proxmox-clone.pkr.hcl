source "proxmox-clone" "k3s" {

  # Proxmox connection settings
  proxmox_url              = var.proxmox_url
  username                 = var.proxmox_username
  password                 = var.proxmox_password
  insecure_skip_tls_verify = true
  node                     = var.proxmox_node

  # The ID of the VM to clone from
  clone_vm_id = "7000"

  # VM General Settings
  vm_id                = var.vm_id_clone
  vm_name              = "k3s-ubuntu-24.04-template"
  template_description = "K3s on Ubuntu Server 24.04 LTS, built with Packer on ${local.buildtime}"

  # cloud-init files
  additional_iso_files {
    type              = "sata"
    index             = 1
    iso_storage_pool  = "local"
    unmount           = true
    keep_cdrom_device = false
    cd_files = ["./k3s/meta-data", "./k3s/user-data"]
    cd_label = "cidata"
  }


  # Explicitly set boot order
  boot = "order=scsi0;net0;sata1"

  # VM System Settings
  qemu_agent = true
  sockets    = "1"
  cpu_type   = "x86-64-v2-AES"
  cores      = "2"
  memory     = "8192"
  os         = "l26"
  machine    = "q35"


  # VM Hard Disk Settings
  scsi_controller = "virtio-scsi-single"
  disks {
    disk_size    = "32G"
    format       = "raw"
    storage_pool = "local-zfs"
    type         = "scsi"
    discard      = true
    ssd          = true
  }

  # VM Network Settings
  network_adapters {
    model  = "virtio"
    bridge = "vmbr0"
  }

  # VM cloud-Init Settings
  cloud_init              = false
  cloud_init_storage_pool = "local-zfs"

  # Communicator settings
  ssh_username         = var.ssh_username
  ssh_private_key_file = var.ssh_private_key_file
  ssh_timeout          = "30m"
}

build {
  name    = "k3s-ubuntu-24.04-template"
  sources = ["source.proxmox-clone.k3s"]

  # Installing K3s
  provisioner "shell" {
    script = "./provisioner-scripts/k3s"
  }

  # Installing Cilium
  provisioner "shell" {
    script = "./provisioner-scripts/cilium"
    expect_disconnect = true
  }
}
