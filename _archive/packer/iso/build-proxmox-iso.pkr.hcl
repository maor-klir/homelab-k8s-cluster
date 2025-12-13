source "proxmox-iso" "ubuntu-24_04-lts" {
  # Proxmox Connection Settings
  proxmox_url              = var.proxmox_url
  username                 = var.proxmox_username
  password                 = var.proxmox_password
  insecure_skip_tls_verify = true
  node                     = var.proxmox_node

  # VM General Settings
  vm_id                = var.vm_id
  vm_name              = "ubuntu-24.04-lts-template"
  template_description = "Ubuntu Server 24.04 LTS template, built with Packer on ${local.buildtime}"

  # VM ISO Settings
  boot_iso {
    type              = "sata"
    iso_file          = var.iso_file
    unmount           = true
    keep_cdrom_device = false
    iso_checksum      = var.iso_checksum
  }

  # Explicitly set boot order
  boot = "order=scsi0;sata0"

  # VM System Settings
  qemu_agent = true
  cores      = "2"
  memory     = "2048"

  # VM Hard Disk Settings
  scsi_controller = "virtio-scsi-single"
  disks {
    disk_size    = "20G"
    format       = "raw"
    storage_pool = "local-zfs"
    type         = "scsi"
    ssd          = true
  }

  # VM Network Settings
  network_adapters {
    model    = "virtio"
    bridge   = "vmbr0"
    firewall = false
  }

  # VM cloud-Init Settings
  cloud_init              = false
  cloud_init_storage_pool = "local-zfs"

  # cloud-init config via additional ISO
  additional_iso_files {
    type              = "sata"
    index             = 1
    iso_storage_pool  = "local"
    unmount           = true
    keep_cdrom_device = false
    cd_files = [
      "./cloud-init/meta-data",
      "./cloud-init/user-data"
    ]
    cd_label = "cidata"
  }

  # Packer boot commands, passing it to the Ubuntu installer
  # This is used to automate the installation process
  # and configure cloud-init to use the provided user-data and meta-data files.
  # The boot command is sent to the VM during the installation process.
  boot_wait = "15s"
  boot_command = [
    "<esc><wait>",
    "e<wait>",
    "<down><down><down><end>",
    " autoinstall quiet ds=nocloud",
    "<f10><wait>",
    "<wait1m>",
    "yes<enter>"
  ]

  # Communicator settings
  ssh_username         = var.ssh_username
  ssh_private_key_file = var.ssh_private_key_file
  ssh_timeout          = "30m"
}

build {
  name    = "ubuntu-24.04-lts"
  sources = ["source.proxmox-iso.ubuntu-24_04-lts"]

  # Provisioning the VM Template
  provisioner "shell" {
    script = "./provisioner-scripts/provision-template"
  }

  # Forcibly eject ISO and prepare for reboot
  provisioner "shell" {
    script = "./provisioner-scripts/eject-iso"
    expect_disconnect = true
  }
}
