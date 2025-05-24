proxmox_url      = "https://192.168.0.102:8006/api2/json"
# proxmox_username = "root@pam"
# Leave token empty here, provide it in secrets.pkrvars.hcl
vm_id = "7001"
iso_file       = "local:iso/ubuntu-24.04.2-live-server-amd64.iso"
ssh_username   = "packer"
ssh_password   = ""
proxmox_node   = "pve-02"