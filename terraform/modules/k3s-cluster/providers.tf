terraform {
  required_version = ">= 1.10.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.97"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "proxmox" {
  # Configuration options
  insecure = true
  ssh {
    agent       = false
    private_key = base64decode(var.private_ssh_key)
  }
}
