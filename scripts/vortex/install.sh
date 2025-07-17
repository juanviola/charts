#!/bin/bash

# Main installation script for Vortex
# This script orchestrates the complete installation process

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${YELLOW}Starting Vortex installation process...${NC}"
echo

# Step 1: Check requirements
echo -e "${YELLOW}Step 1: Checking requirements...${NC}"
if ! "${SCRIPT_DIR}/requirements.sh"; then
    echo -e "${RED}✗ Requirements check failed. Installation aborted.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Requirements check passed${NC}"
echo

# Step 2: Install Vault
echo -e "${YELLOW}Step 2: Installing Vault...${NC}"
if ! "${SCRIPT_DIR}/install.vault.sh"; then
    echo -e "${RED}✗ Vault installation failed. Installation aborted.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Vault installation completed${NC}"
echo

# Step 3: Helm upgrade
echo -e "${YELLOW}Step 3: Running final install...${NC}"
NAMESPACE=vortex
HELM_CHART_PATH="${SCRIPT_DIR}/../../helm/vortex"
MARIADB_ROOT_PASSWORD=$(kubectl get secret --namespace ${NAMESPACE} mysql -o jsonpath="{.data.mariadb-root-password}" | base64 -d)

if helm upgrade --install --namespace=${NAMESPACE} --create-namespace vortex "${HELM_CHART_PATH}" -f config.yaml; then
    echo -e "${GREEN}✓ Helm upgrade completed successfully${NC}"
else
    echo -e "${RED}✗ Helm upgrade failed${NC}"
    exit 1
fi

echo
echo -e "${GREEN}🎉 Vortex installation completed successfully!${NC}"
echo -e "${YELLOW}You can now access your Vortex deployment in the '${NAMESPACE}' namespace${NC}"