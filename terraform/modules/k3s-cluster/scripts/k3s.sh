#!/usr/bin/env bash
set -euo pipefail

# Install K3s on the control plane node(s)
curl -sfL https://get.k3s.io | sh -s - --config=/etc/rancher/k3s/config.yaml
