#!/bin/bash

# Deploy ArgoCD applications with proper AppProject setup

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  ArgoCD Deployment Script                     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}✗ kubectl not found. Please install kubectl first.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ kubectl found${NC}"
echo ""



echo ""

# Wait a moment for the project to be ready
sleep 2

# Step 2: Ask which environment to deploy
echo "Select environment to deploy:"
echo "  1) Development (auto-sync enabled)"
echo "  2) Staging (auto-sync enabled)"
echo "  3) Production (manual sync)"
echo "  4) All environments"
read -p "Enter choice [1-4]: " ENV_CHOICE

deploy_app() {
    local env=$1
    local file="argocd/application-${env}.yaml"
    local app_name="http-hello-world-${env}"

    if [ "$env" = "prod" ]; then
        app_name="http-hello-world-prod"
    fi

    echo -e "${BLUE}📦 Deploying ${env} environment...${NC}"

    if kubectl apply -f "$file"; then
        echo -e "${GREEN}✓ ${env} application created${NC}"

        # Wait for app to be registered
        sleep 2

        # Show app status
        if command -v argocd &> /dev/null; then
            echo -e "${BLUE}Application status:${NC}"
            argocd app get "$app_name" --refresh 2>/dev/null || echo -e "${YELLOW}Use ArgoCD UI to check status${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Failed to create ${env} application${NC}"
        return 1
    fi
}

echo ""

case $ENV_CHOICE in
    1)
        deploy_app "dev"
        ;;
    2)
        deploy_app "staging"
        ;;
    3)
        deploy_app "prod"
        echo ""
        echo -e "${YELLOW}ℹ️  Production requires manual sync:${NC}"
        if command -v argocd &> /dev/null; then
            echo "    argocd app sync http-hello-world-prod"
        else
            echo "    Use ArgoCD UI to sync the application"
        fi
        ;;
    4)
        deploy_app "dev"
        echo ""
        deploy_app "staging"
        echo ""
        deploy_app "prod"
        echo ""
        echo -e "${YELLOW}ℹ️  Production requires manual sync${NC}"
        ;;
    *)
        echo -e "${YELLOW}⚠️  Invalid choice${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}✅ Deployment complete!${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}Next steps:${NC}"
echo ""
echo "1️⃣  Access ArgoCD UI:"
echo "   kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "   Open: https://localhost:8080"
echo ""
echo "2️⃣  Get admin password:"
echo "   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d && echo"
echo ""
echo "3️⃣  Check application status:"
if command -v argocd &> /dev/null; then
    echo "   argocd app list"
    echo "   argocd app get http-hello-world-dev"
else
    echo "   kubectl get applications -n argocd"
    echo "   kubectl describe application http-hello-world-dev -n argocd"
fi
echo ""
echo "4️⃣  View deployed resources:"
echo "   kubectl get all -n dev -l app=http-hello-world"
echo ""
echo "5️⃣  Test the application:"
echo "   kubectl port-forward -n dev svc/http-hello-world-dev 8080:80"
echo "   curl http://localhost:8080"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
