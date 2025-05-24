# resource "proxmox_virtual_environment_file" "pve-env-file-worker" {
#   provider     = proxmox.euclid
#   node_name    = var.euclid.node_name
#   content_type = "snippets"
#   datastore_id = "local"

#   source_raw {
#     data = templatefile("./cloud-init/k3s-worker.tftpl", {
#       common-config = templatefile("./cloud-init/k8s-common.yaml.tftpl", {
#         hostname = "k3s-worker-01"
#         username = var.vm_username
#         password = var.vm_password
#         pub-key  = var.host_public_key
#         k3s-cmd  = <<-EOT
#         curl -sfL https://get.k3s.io | sh -s - \
#         --flannel-backend=none \
#         --disable-kube-proxy \
#         --disable servicelb \
#         --disable-network-policy \
#         --disable traefik \
#         --cluster-init
#         EOT
#       })
#     })
#     file_name = "pve-env-file-worker.yaml"
#   }
# }
