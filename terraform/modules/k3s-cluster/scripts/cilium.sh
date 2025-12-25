#!/usr/bin/env bash
set -euo pipefail

# Install Helm
curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | \
tee /etc/apt/sources.list.d/helm-stable-debian.list
apt-get update
apt-get install -y helm

# Set kubeconfig for Helm commands
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Deploy Cilium using Helm, installing the latest Cilium chart with custom values
helm repo add cilium https://helm.cilium.io/
helm repo update
helm upgrade --install cilium cilium/cilium \
--namespace kube-system \
--values /root/cilium-values.yaml
