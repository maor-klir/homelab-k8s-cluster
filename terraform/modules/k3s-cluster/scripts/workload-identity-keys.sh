#!/usr/bin/env bash
set -euo pipefail

KEY_DIR="/var/lib/rancher/k3s/server/tls"
PRIVATE_KEY="${KEY_DIR}/workload-identity-sa.key"
PUBLIC_KEY="${KEY_DIR}/workload-identity-sa.pub"
JWKS_OUTPUT="/root/jwks.json"

# Ensure directory exists
mkdir -p "${KEY_DIR}"

# Generate RSA private key
openssl genrsa -out "${PRIVATE_KEY}" 2048

# Generate RSA public key from private key
openssl rsa -in "${PRIVATE_KEY}" -pubout -out "${PUBLIC_KEY}"

# Set proper permissions
chmod 600 "${PRIVATE_KEY}"
chmod 644 "${PUBLIC_KEY}"

# Install latest azwi
AZWI_VERSION=$(curl -sf https://api.github.com/repos/Azure/azure-workload-identity/releases/latest | jq -r '.tag_name')
if [ -z "$AZWI_VERSION" ]; then
    echo "Failed to fetch latest azwi version, using fallback"
    AZWI_VERSION="v1.5.1"
fi
wget -q "https://github.com/Azure/azure-workload-identity/releases/download/${AZWI_VERSION}/azwi-${AZWI_VERSION}-linux-amd64.tar.gz"
tar -xzf "azwi-${AZWI_VERSION}-linux-amd64.tar.gz" -C /tmp
mv /tmp/azwi /usr/local/bin/azwi
chmod +x /usr/local/bin/azwi
rm -f "azwi-${AZWI_VERSION}-linux-amd64.tar.gz"

# Generate JWKS document
azwi jwks --public-keys "${PUBLIC_KEY}" --output-file "${JWKS_OUTPUT}"
