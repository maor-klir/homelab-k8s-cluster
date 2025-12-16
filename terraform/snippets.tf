resource "proxmox_virtual_environment_file" "cloud-init-k3s-cp-01" {
  node_name    = var.pve_node_name[0]
  content_type = "snippets"
  datastore_id = "local"

  source_raw {
    data = templatefile("./cloud-init/general.yaml.tftpl", {
      hostname   = "k3s-cp-01"
      username   = var.k3s_vm_user
      public-key = var.k3s_public_key
    })
    file_name = "cloud-init-k3s-cp-01.yaml"
  }
}
