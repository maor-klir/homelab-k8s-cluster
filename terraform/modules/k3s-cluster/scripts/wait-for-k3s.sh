#!/usr/bin/env bash
set -euo pipefail

# Wait for the K3s API server to become operational before trying to deploy Cilium
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

for i in {1..60}; do
  if kubectl get nodes >/dev/null 2>&1; then
    echo "K3s API server is ready!"
    exit 0
  fi
  sleep 5
done

echo "K3s API server did not become ready in time" >&2
exit 1
