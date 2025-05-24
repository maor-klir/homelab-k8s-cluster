# source "proxmox-iso" "ubuntu-2404" {
#   # Proxmox Connection Settings
#   proxmox_url              = var.proxmox_url
#   username                 = var.proxmox_username
#   token                    = var.proxmox_token
#   insecure_skip_tls_verify = true
#   node                     = var.proxmox_node

#   # VM General Settings
#   vm_id                = var.vm_id
#   vm_name              = "ubuntu-2404-template"
#   template_description = "Ubuntu 24.04 Server Template, built with Packer on ${local.buildtime}"

#   # VM ISO Settings

#   boot_iso {
#     type              = "ide"
#     iso_file          = var.iso_file
#     unmount           = true
#     keep_cdrom_device = false
#     iso_checksum      = var.iso_checksum
#   }

#   # Explicitly set boot order to prefer scsi0 (installed disk) over ide devices
#   boot = "order=scsi0;net0;ide0"

#   # VM System Settings
#   qemu_agent = true
#   cores      = "2"
#   memory     = "2048"

#   # VM Hard Disk Settings
#   scsi_controller = "virtio-scsi-single"

#   disks {
#     disk_size    = "20G"
#     format       = "raw"
#     storage_pool = "local-lvm"
#     type         = "scsi"
#     ssd          = true
#   }

#   # VM Network Settings
#   network_adapters {
#     model    = "virtio"
#     bridge   = "vmbr0"
#     firewall = false
#   }

#   # VM Cloud-Init Settings
#   cloud_init              = true
#   cloud_init_storage_pool = "local-lvm"

#   # Cloud-init config via additional ISO
#   additional_iso_files {
#     type              = "ide"
#     index             = 1
#     iso_storage_pool  = "local"
#     unmount           = true
#     keep_cdrom_device = false
#     cd_files = [
#       "./http/meta-data",
#       "./http/user-data"
#     ]
#     cd_label = "cidata"
#   }

#   # PACKER Boot Commands
#   boot_wait = "10s"
#   boot_command = [
#     "<esc><wait>",
#     "e<wait>",
#     "<down><down><down><end>",
#     " autoinstall quiet ds=nocloud",
#     "<f10><wait>",
#     "<wait1m>",
#     "yes<enter>"
#   ]

#   # Communicator Settings
#   ssh_username = var.ssh_username
#   ssh_password = var.ssh_password
#   ssh_timeout  = "30m"
# }