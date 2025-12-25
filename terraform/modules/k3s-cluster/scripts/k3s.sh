#!/usr/bin/env bash
set -euo pipefail

# Install K3s on the control plane node(s)
curl -sfL https://get.k3s.io | sh -s - \
--token "${k3s_token}" \
--flannel-backend=none \
--disable-helm-controller \
--disable-kube-proxy \
--disable=servicelb \
--disable-network-policy \
--disable traefik \
--cluster-init
