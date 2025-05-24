resource "proxmox_virtual_environment_download_file" "ubuntu" {
  provider     = proxmox
  node_name    = "pve-02"
  content_type = "iso"
  datastore_id = "local"

  file_name          = "ubuntu-24.04-server-cloudimg-amd64.img"
  url                = "https://cloud-images.ubuntu.com/releases/releases/24.04/release-20250516/ubuntu-24.04-server-cloudimg-amd64.img"
  checksum           = "8d6161defd323d24d66f85dda40e64e2b9021aefa4ca879dcbc4ec775ad1bbc5"
  checksum_algorithm = "sha256"
}

resource "proxmox_virtual_environment_file" "pve-cp" {
  provider     = proxmox
  node_name    = "pve-02"
  content_type = "snippets"
  datastore_id = "local"

  source_raw {
    data = <<-EOF
    #cloud-config

    users:
      - name: ${var.vm_username}
        passwd: ${var.vm_password}
        lock_passwd: false
        groups: [ sudo ]
        shell: /usr/bin/bash
        ssh_authorized_keys:
          - ${var.host_public_key}

    hostname: ${var.vm_hostname}
    package_update: true
    package_upgrade: true
    timezone: Europe/Berlin

    # write_files:
    #   - path: /etc/ssh/sshd_config.d/01-ssh-hardening.conf
    #     content: |
    #       PermitRootLogin no
    #       PasswordAuthentication no
    #       ChallengeResponseAuthentication no
    #       UsePAM no

    packages:
      - qemu-guest-agent
      - curl
      - net-tools
      - vim
      - ca-certificates
      - jq

    # power_state:
    #     delay: now
    #     mode: reboot
    #     message: "Rebooting after cloud-init has finished applying its configuration."
    #     condition: true

    # runcmd:
    #   - systemctl enable qemu-guest-agent
    #   - localectl set-locale LANG=en_US.UTF-8
    #   - curl -sfL https://get.k3s.io | sh -s - \
    #     --flannel-backend=none \
    #     --disable-kube-proxy \
    #     --disable servicelb \
    #     --disable-network-policy \
    #     --disable traefik \
    #     --write-kubeconfig-mode 600 \
    #     --cluster-init

    #   - mkdir -p $HOME/.kube
    #   - sudo cp -i /etc/rancher/k3s/k3s.yaml $HOME/.kube/config
    #   - sudo chown $(id -u):$(id -g) $HOME/.kube/config
    #   - echo "export KUBECONFIG=$HOME/.kube/config" >> $HOME/.bashrc
    #   - source $HOME/.bashrc
    #   - curl -sfLO https://github.com/cilium/cilium-cli/releases/download/v${var.cilium_cli_version}/cilium-linux-amd64.tar.gz
    #   - tar xzvfC cilium-linux-amd64.tar.gz /usr/local/bin
    #   - rm cilium-linux-amd64.tar.gz

    #   - cilium install --version 1.17.4 \
    #   --set operator.replicas=1 \
    #   --set kubeProxyReplacement=true \
    #   --set ipam.mode=kubernetes \
    #   --set gatewayAPI.enabled=true \
    #   --set l2announcements.enabled=true \
    #   --set hubble.relay.enabled=true \
    #   --set hubble.ui.enabled=true \
    #   --set k8sClientRateLimit.qps=5 \
    #   --set k8sClientRateLimit.burst=10 \
    #   --set multiPoolPreAllocation=null
      EOF

    file_name = "pve-cp.yaml"
  }
}

# resource "proxmox_virtual_environment_file" "pve-cp" {
#   provider     = proxmox
#   node_name    = "pve-02"
#   content_type = "snippets"
#   datastore_id = "local"

#   source_raw {
#     data = templatefile("./cloud-init/k3s-control-plane.tftpl", {
#       general-config = templatefile("./cloud-init/general-config.tftpl", {
#         hostname   = "k3s-cp-01"
#         username   = var.vm_username
#         password   = var.vm_password
#         public-key = var.host_public_key
#         k3s-cmd    = <<-EOF
#         curl -sfL https://get.k3s.io | sh -s - \
#         --flannel-backend=none \
#         --disable-kube-proxy \
#         --disable servicelb \
#         --disable-network-policy \
#         --disable traefik \
#         --write-kubeconfig-mode 600 \
#         --cluster-init
#         EOF
#       })
#       username           = var.vm_username
#       cilium-cli-version = var.cilium_cli_version
#       cilium-cli-cmd     = <<-EOF
#       cilium install --version 1.17.4 \
#       --set operator.replicas=1 \
#       --set kubeProxyReplacement=true \
#       --set ipam.mode=kubernetes \
#       --set gatewayAPI.enabled=true \
#       --set l2announcements.enabled=true \
#       --set hubble.relay.enabled=true \
#       --set hubble.ui.enabled=true \
#       --set k8sClientRateLimit.qps=5 \
#       --set k8sClientRateLimit.burst=10 \
#       --set multiPoolPreAllocation=null
#       EOF
#     })
#     file_name = "bootstrap-cp.yaml"
#   }
# }
