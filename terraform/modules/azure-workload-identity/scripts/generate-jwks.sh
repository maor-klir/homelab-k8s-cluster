#!/usr/bin/env bash
set -euo pipefail

# This script generates JWKS from a public key PEM
# Input: JSON on stdin with "public_key_pem" field
# Output: JSON with "jwks" field containing the JWKS document

# Read input JSON
eval "$(jq -r '@sh "PUBLIC_KEY_PEM=\(.public_key_pem)"')"

# Create temporary files
TEMP_DIR=$(mktemp -d)
trap "rm -rf ${TEMP_DIR}" EXIT

PUBLIC_KEY_FILE="${TEMP_DIR}/public_key.pem"
JWKS_FILE="${TEMP_DIR}/jwks.json"

# Write public key to file
echo "${PUBLIC_KEY_PEM}" > "${PUBLIC_KEY_FILE}"

# Check if azwi is installed, if not install it
if ! command -v azwi &> /dev/null; then
    AZWI_VERSION=$(curl -sf https://api.github.com/repos/Azure/azure-workload-identity/releases/latest | jq -r '.tag_name')
    if [ -z "$AZWI_VERSION" ]; then
        AZWI_VERSION="v1.5.1"
    fi
    wget -q "https://github.com/Azure/azure-workload-identity/releases/download/${AZWI_VERSION}/azwi-${AZWI_VERSION}-linux-amd64.tar.gz" -O /tmp/azwi.tar.gz
    tar -xzf /tmp/azwi.tar.gz -C /tmp
    mv /tmp/azwi /usr/local/bin/
fi

# Generate JWKS
azwi jwks --public-keys "${PUBLIC_KEY_FILE}" --output-file "${JWKS_FILE}"

# Read JWKS and output as JSON
JWKS_CONTENT=$(cat "${JWKS_FILE}")
jq -n --arg jwks "${JWKS_CONTENT}" '{"jwks":$jwks}'
