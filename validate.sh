#!/bin/bash

# Quick test script to validate Kustomize manifests

set -e

echo "🔍 Validating Kustomize manifests..."
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

validate_overlay() {
    local overlay=$1
    echo -e "${YELLOW}Checking ${overlay}...${NC}"

    if kubectl kustomize "overlays/${overlay}" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ ${overlay} is valid${NC}"
        return 0
    else
        echo -e "${RED}✗ ${overlay} has errors${NC}"
        kubectl kustomize "overlays/${overlay}"
        return 1
    fi
}

# Validate base
echo -e "${YELLOW}Checking base...${NC}"
if kubectl kustomize base > /dev/null 2>&1; then
    echo -e "${GREEN}✓ base is valid${NC}"
else
    echo -e "${RED}✗ base has errors${NC}"
    kubectl kustomize base
    exit 1
fi

echo ""

# Validate overlays
validate_overlay "dev"
echo ""
validate_overlay "staging"
echo ""
validate_overlay "production"

echo ""
echo -e "${GREEN}✓ All manifests are valid!${NC}"
echo ""
echo "To view rendered manifests:"
echo "  kubectl kustomize overlays/dev"
echo "  kubectl kustomize overlays/staging"
echo "  kubectl kustomize overlays/production"
