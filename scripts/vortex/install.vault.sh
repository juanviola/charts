#!/bin/bash

# Script to install Vault with Vortex Helm chart and handle initialization/unsealing
# Required commands: kubectl, jq, helm, vault

set -e

# Colors output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

NAMESPACE=vortex
VAULT_POD="vortex-vault-0"
VAULT_INIT_FILE="vault-init.json"

echo -e "${YELLOW}Installing Vault with Helm...${NC}"
helm upgrade --install --namespace=${NAMESPACE} --create-namespace vortex ../../helm/vortex --set "vault.enabled=true"

echo -e "${YELLOW}Waiting for Vault pod to be ready...${NC}"
while true; do
  # Check if the pod is running
  if kubectl get pods -n ${NAMESPACE} ${VAULT_POD} -o json 2>/dev/null | jq -e '.status.phase == "Running"' >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Vault Pod is running${NC}"
    break
  fi
  echo -e "${YELLOW}Waiting for Vault pod to be ready...${NC}"
  sleep 10
done

# Check if the pod is initialized
is_vault_initialized() {
  kubectl -n ${NAMESPACE} exec ${VAULT_POD} -- vault status --format=json 2>/dev/null | jq -r '.initialized'
}

# Check if the pod is sealed
is_vault_sealed() {
  kubectl -n ${NAMESPACE} exec ${VAULT_POD} -- vault status --format=json 2>/dev/null | jq -r '.sealed'
}

echo -e "${YELLOW}Checking Vault status...${NC}"

# Check if the pod is initialized
if [ "$(is_vault_initialized)" = "false" ]; then
  echo -e "${YELLOW}Vault is not initialized. Initializing...${NC}"
  
  # Start the initialization process
  kubectl -n ${NAMESPACE} exec ${VAULT_POD} -- vault operator init --format=json > ${VAULT_INIT_FILE}
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Vault initialization completed successfully${NC}"
    echo -e "${YELLOW}Initialization keys saved in ${VAULT_INIT_FILE}${NC}"
  else
    echo -e "${RED}✗ Error initializing Vault${NC}"
    exit 1
  fi
else
  echo -e "${GREEN}✓ Vault is already initialized${NC}"
fi

# Check if the pod is sealed
if [ "$(is_vault_sealed)" = "true" ]; then
  echo -e "${YELLOW}Vault is sealed. Unsealing...${NC}"
  
  # Check if the initialization file exists
  if [ ! -f "${VAULT_INIT_FILE}" ]; then
    echo -e "${RED}✗ Can't find the initialization file ${VAULT_INIT_FILE} with unseal keys${NC}"
    echo -e "${YELLOW}Please provide the unseal keys manually${NC}"
    exit 1
  fi
  
  # Extract the unseal keys from the JSON file
  unseal_keys=$(jq -r '.unseal_keys_b64[]' ${VAULT_INIT_FILE})
  
  # Unseal the Vault with the first 3 keys (default threshold)
  count=0
  for key in $unseal_keys; do
    if [ $count -lt 3 ]; then
      echo -e "${YELLOW}Applying unseal key $((count + 1))/3...${NC}"
      kubectl -n ${NAMESPACE} exec ${VAULT_POD} -- vault operator unseal "$key"
      count=$((count + 1))
    fi
  done
  
  # Check if the unseal was successful
  if [ "$(is_vault_sealed)" = "false" ]; then
    echo -e "${GREEN}✓ Vault is unsealed${NC}"
  else
    echo -e "${RED}✗ Error unsealing Vault${NC}"
    exit 1
  fi
else
  echo -e "${GREEN}✓ Vault is already unsealed${NC}" 
fi

# create a secret for the vault init script
kubectl -n ${NAMESPACE} create secret generic vault-init --from-file=vault-init.json
echo -e "${GREEN}✓ Secret vault-init created...${NC}" 

# create base secrets on Vault
## generate random passwords for MYSQL, REDIS, RABBITMQ
./randpass.sh

# copy the secrets to vault pod
echo -e "${GREEN}✓ Copying secrets to vault pod..." 
kubectl -n ${NAMESPACE} cp default-env/global-core.json ${VAULT_POD}:/tmp/global-core.json
kubectl -n ${NAMESPACE} cp default-env/engine-core.json ${VAULT_POD}:/tmp/engine-core.json
kubectl -n ${NAMESPACE} cp default-env/admin-core.json ${VAULT_POD}:/tmp/admin-core.json
kubectl -n ${NAMESPACE} cp default-env/gateway-core.json ${VAULT_POD}:/tmp/gateway-core.json
kubectl -n ${NAMESPACE} cp default-env/gateway-websocket-core.json ${VAULT_POD}:/tmp/gateway-websocket-core.json
kubectl -n ${NAMESPACE} cp default-env/portal-core.json ${VAULT_POD}:/tmp/portal-core.json
kubectl -n ${NAMESPACE} cp default-env/scheduler-core.json ${VAULT_POD}:/tmp/scheduler-core.json
kubectl -n ${NAMESPACE} cp default-env/worker-audit-core.json ${VAULT_POD}:/tmp/worker-audit-core.json
kubectl -n ${NAMESPACE} cp default-env/worker-core.json ${VAULT_POD}:/tmp/worker-core.json
kubectl -n ${NAMESPACE} cp default-env/workspace-core.json ${VAULT_POD}:/tmp/workspace-core.json

# get vault root token
TOKEN=$(kubectl -n ${NAMESPACE} get secret vault-init -o jsonpath='{.data.vault-init\.json}' | base64 -d | jq -r '.root_token')

# create external secrets token
kubectl -n ${NAMESPACE} create secret generic es-token --from-literal=token=${TOKEN}

# create the secrets 
kubectl exec -n ${NAMESPACE} -it ${VAULT_POD} -- vault login ${TOKEN}
kubectl exec -n ${NAMESPACE} -it ${VAULT_POD} -- vault secrets enable -path=secret kv-v2
## global
kubectl exec -n ${NAMESPACE} -it ${VAULT_POD} -- vault kv put secret/global/core @/tmp/global-core.json
kubectl exec -n ${NAMESPACE} -it ${VAULT_POD} -- vault kv put secret/global/datasources empty=true
## engine
kubectl exec -n ${NAMESPACE} -it ${VAULT_POD} -- vault kv put secret/engine/core @/tmp/engine-core.json
## gateway
kubectl exec -n ${NAMESPACE} -it ${VAULT_POD} -- vault kv put secret/gateway/core @/tmp/gateway-core.json
## gateway websocket
kubectl exec -n ${NAMESPACE} -it ${VAULT_POD} -- vault kv put secret/gateway-websocket/core @/tmp/gateway-websocket-core.json
## portal
kubectl exec -n ${NAMESPACE} -it ${VAULT_POD} -- vault kv put secret/portal/core @/tmp/portal-core.json
## workspace
kubectl exec -n ${NAMESPACE} -it ${VAULT_POD} -- vault kv put secret/workspace/core @/tmp/workspace-core.json
## scheduler
kubectl exec -n ${NAMESPACE} -it ${VAULT_POD} -- vault kv put secret/scheduler/core @/tmp/scheduler-core.json
## admin
kubectl exec -n ${NAMESPACE} -it ${VAULT_POD} -- vault kv put secret/admin/core @/tmp/admin-core.json
## worker
kubectl exec -n ${NAMESPACE} -it ${VAULT_POD} -- vault kv put secret/worker/core @/tmp/worker-core.json
## worker audit
kubectl exec -n ${NAMESPACE} -it ${VAULT_POD} -- vault kv put secret/worker-audit/core @/tmp/worker-audit-core.json

# Installing external secrets
echo -e "${YELLOW}Installing External Secrets with Helm...${NC}"
helm upgrade --install --namespace=${NAMESPACE} --create-namespace vortex ../../helm/vortex --set "vault.enabled=true" --set "externalSecrets.enabled=true"


echo -e "${GREEN}✓ Installation and configuration of Vault completed${NC}"
echo -e "${YELLOW}Token root: $(jq -r '.root_token' ${VAULT_INIT_FILE} 2>/dev/null || echo 'Not available')${NC}"