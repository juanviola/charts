#!/bin/bash

# Script to clean up Vortex namespace after a failed installation
# This script removes all resources that might be left behind
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

NAMESPACE=vortex
HELM_RELEASE=vortex
VAULT_INIT_FILE="vault-init.json"

echo -e "${YELLOW}Starting cleanup of Vortex namespace...${NC}"
echo

# Function to check if namespace exists
namespace_exists() {
    kubectl get namespace "$NAMESPACE" >/dev/null 2>&1
}

# Function to check if helm release exists
helm_release_exists() {
    helm list -n "$NAMESPACE" | grep -q "$HELM_RELEASE" 2>/dev/null
}

# Step 1: Uninstall Helm release
echo -e "${YELLOW}Step 1: Removing Helm release...${NC}"
if helm_release_exists; then
    if helm uninstall "$HELM_RELEASE" -n "$NAMESPACE"; then
        echo -e "${GREEN}✓ Helm release '$HELM_RELEASE' removed${NC}"
    else
        echo -e "${RED}✗ Failed to remove Helm release '$HELM_RELEASE'${NC}"
    fi
else
    echo -e "${YELLOW}ℹ Helm release '$HELM_RELEASE' not found${NC}"
fi
echo

# Step 2: Wait for pods to terminate
echo -e "${YELLOW}Step 2: Waiting for pods to terminate...${NC}"
if namespace_exists; then
    timeout=60
    while [ $timeout -gt 0 ]; do
        pod_count=$(kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l || echo "0")
        if [ "$pod_count" -eq 0 ]; then
            echo -e "${GREEN}✓ All pods terminated${NC}"
            break
        fi
        echo -e "${YELLOW}Waiting for $pod_count pods to terminate... (${timeout}s remaining)${NC}"
        sleep 5
        timeout=$((timeout - 5))
    done
    
    if [ $timeout -eq 0 ]; then
        echo -e "${RED}⚠ Timeout waiting for pods to terminate. Forcing cleanup...${NC}"
        kubectl delete pods --all -n "$NAMESPACE" --force --grace-period=0 2>/dev/null || true
    fi
fi
echo

# Step 3: Remove PVCs
echo -e "${YELLOW}Step 3: Removing Persistent Volume Claims...${NC}"
if namespace_exists; then
    pvcs=$(kubectl get pvc -n "$NAMESPACE" --no-headers 2>/dev/null | awk '{print $1}' || true)
    if [ -n "$pvcs" ]; then
        for pvc in $pvcs; do
            if kubectl delete pvc "$pvc" -n "$NAMESPACE"; then
                echo -e "${GREEN}✓ PVC '$pvc' removed${NC}"
            else
                echo -e "${RED}✗ Failed to remove PVC '$pvc'${NC}"
            fi
        done
    else
        echo -e "${YELLOW}ℹ No PVCs found${NC}"
    fi
fi
echo

# Step 4: Remove Secrets
echo -e "${YELLOW}Step 4: Removing Secrets...${NC}"
if namespace_exists; then
    secrets=$(kubectl get secrets -n "$NAMESPACE" --no-headers 2>/dev/null | grep -v "default-token" | awk '{print $1}' || true)
    if [ -n "$secrets" ]; then
        for secret in $secrets; do
            if kubectl delete secret "$secret" -n "$NAMESPACE"; then
                echo -e "${GREEN}✓ Secret '$secret' removed${NC}"
            else
                echo -e "${RED}✗ Failed to remove Secret '$secret'${NC}"
            fi
        done
    else
        echo -e "${YELLOW}ℹ No custom secrets found${NC}"
    fi
fi
echo

# Step 5: Remove ConfigMaps
echo -e "${YELLOW}Step 5: Removing ConfigMaps...${NC}"
if namespace_exists; then
    configmaps=$(kubectl get configmaps -n "$NAMESPACE" --no-headers 2>/dev/null | grep -v "kube-root-ca.crt" | awk '{print $1}' || true)
    if [ -n "$configmaps" ]; then
        for cm in $configmaps; do
            if kubectl delete configmap "$cm" -n "$NAMESPACE"; then
                echo -e "${GREEN}✓ ConfigMap '$cm' removed${NC}"
            else
                echo -e "${RED}✗ Failed to remove ConfigMap '$cm'${NC}"
            fi
        done
    else
        echo -e "${YELLOW}ℹ No custom ConfigMaps found${NC}"
    fi
fi
echo

# Step 6: Remove Services
echo -e "${YELLOW}Step 6: Removing Services...${NC}"
if namespace_exists; then
    services=$(kubectl get services -n "$NAMESPACE" --no-headers 2>/dev/null | awk '{print $1}' || true)
    if [ -n "$services" ]; then
        for svc in $services; do
            if kubectl delete service "$svc" -n "$NAMESPACE"; then
                echo -e "${GREEN}✓ Service '$svc' removed${NC}"
            else
                echo -e "${RED}✗ Failed to remove Service '$svc'${NC}"
            fi
        done
    else
        echo -e "${YELLOW}ℹ No services found${NC}"
    fi
fi
echo

# Step 7: Remove any remaining resources
echo -e "${YELLOW}Step 7: Removing any remaining resources...${NC}"
if namespace_exists; then
    # Remove deployments, statefulsets, daemonsets, etc.
    resource_types=("deployments" "statefulsets" "daemonsets" "replicasets" "jobs" "cronjobs")
    for resource_type in "${resource_types[@]}"; do
        resources=$(kubectl get "$resource_type" -n "$NAMESPACE" --no-headers 2>/dev/null | awk '{print $1}' || true)
        if [ -n "$resources" ]; then
            for resource in $resources; do
                if kubectl delete "$resource_type" "$resource" -n "$NAMESPACE"; then
                    echo -e "${GREEN}✓ $resource_type '$resource' removed${NC}"
                else
                    echo -e "${RED}✗ Failed to remove $resource_type '$resource'${NC}"
                fi
            done
        fi
    done
fi
echo

# Step 8: Remove the namespace
echo -e "${YELLOW}Step 8: Removing namespace...${NC}"
if namespace_exists; then
    if kubectl delete namespace "$NAMESPACE"; then
        echo -e "${GREEN}✓ Namespace '$NAMESPACE' removed${NC}"
    else
        echo -e "${RED}✗ Failed to remove namespace '$NAMESPACE'${NC}"
        echo -e "${YELLOW}You may need to manually remove finalizers or stuck resources${NC}"
    fi
else
    echo -e "${YELLOW}ℹ Namespace '$NAMESPACE' not found${NC}"
fi
echo

# Step 9: Clean up local files
echo -e "${YELLOW}Step 9: Cleaning up local files...${NC}"
if [ -f "$VAULT_INIT_FILE" ]; then
    if rm "$VAULT_INIT_FILE"; then
        echo -e "${GREEN}✓ Local file '$VAULT_INIT_FILE' removed${NC}"
    else
        echo -e "${RED}✗ Failed to remove local file '$VAULT_INIT_FILE'${NC}"
    fi
else
    echo -e "${YELLOW}ℹ Local file '$VAULT_INIT_FILE' not found${NC}"
fi

echo
echo -e "${GREEN}🧹 Cleanup completed!${NC}"
echo -e "${YELLOW}The Vortex namespace and all associated resources have been removed.${NC}"
echo -e "${YELLOW}You can now run a fresh installation if needed.${NC}"