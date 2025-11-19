terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.86.0"
    }
  }
}

provider "proxmox" {
  endpoint  = "https://192.168.0.102:8006"
  insecure  = true
  ssh {
    agent    = true
    username = "root"
  }
}
