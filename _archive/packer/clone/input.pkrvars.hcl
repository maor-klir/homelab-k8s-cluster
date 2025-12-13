proxmox_url          = "https://192.168.0.102:8006/api2/json" # The Proxmox VE API endpoint, using an IP address will not work
vm_id                = "7000"
iso_file             = "local:iso/ubuntu-24.04.2-live-server-amd64.iso"
iso_checksum         = "sha256:d6dab0c3a657988501b4bd76f1297c053df710e06e0c3aece60dead24f270b4d"
ssh_username         = "ubuntu"
ssh_public_key       = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJhj7pZo8NRSMFGFkuUiO8hEJF+eohqfydweD/UUN2d/ maor@fedora-workstation"
ssh_private_key_file = "~/.ssh/packer_communicator"
proxmox_node         = "pve-02"
