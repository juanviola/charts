#!/bin/bash

# Script to verify requirements for the Vortex Helm chart
# Required commands: kubectl, jq, helm, pulumi

set -e

# Colors output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if a command exists
check_command() {
    local cmd=$1
    if command -v "$cmd" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $cmd is available"
        return 0
    else
        echo -e "${RED}✗${NC} $cmd is not available"
        return 1
    fi
}

echo -e "${YELLOW}Verifying required commands...${NC}"
echo

# List of required commands
required_commands=("kubectl" "jq" "helm")
missing_commands=()

# Verify required commands
for cmd in "${required_commands[@]}"; do
    if ! check_command "$cmd"; then
        missing_commands+=("$cmd")
    fi
done

echo

# If there are missing commands, show error and exit
if [ ${#missing_commands[@]} -gt 0 ]; then
    echo -e "${RED}Error: The following commands are not available:${NC}"
    for cmd in "${missing_commands[@]}"; do
        echo -e "  ${RED}- $cmd${NC}"
    done
    echo
    echo -e "${YELLOW}Please install the missing commands before continuing.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ All the commands are available${NC}"
exit 0