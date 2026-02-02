#!/bin/bash

# Quick start script for deploying to ArgoCD

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  HTTP Hello World - ArgoCD Quick Start        ║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${YELLOW}⚠️  kubectl not found. Please install kubectl first.${NC}"
    exit 1
fi

# Check if argocd CLI is available
ARGOCD_CLI=false
if command -v argocd &> /dev/null; then
    ARGOCD_CLI=true
fi

echo -e "${GREEN}✓ kubectl found${NC}"
if [ "$ARGOCD_CLI" = true ]; then
    echo -e "${GREEN}✓ argocd CLI found${NC}"
else
    echo -e "${YELLOW}ℹ️  argocd CLI not found (optional)${NC}"
fi
echo ""

# Prompt for repository URL
read -p "Enter your Git repository URL (e.g., https://github.com/user/repo.git): " REPO_URL

if [ -z "$REPO_URL" ]; then
    echo -e "${YELLOW}⚠️  Repository URL is required${NC}"
    exit 1
fi

# Update ArgoCD application manifests with the repo URL
echo -e "${BLUE}📝 Updating ArgoCD application manifests...${NC}"
sed -i.bak "s|https://github.com/YOUR_USERNAME/http-hello-world-argocd.git|$REPO_URL|g" argocd/application-*.yaml
rm -f argocd/application-*.yaml.bak
echo -e "${GREEN}✓ Manifests updated${NC}"
echo ""

# Ask which environment to deploy
echo "Select environment to deploy:"
echo "  1) Development (auto-sync enabled)"
echo "  2) Staging (auto-sync enabled)"
echo "  3) Production (manual sync)"
echo "  4) All environments"
read -p "Enter choice [1-4]: " ENV_CHOICE

deploy_app() {
    local env=$1
    local file="argocd/application-${env}.yaml"

    echo -e "${BLUE}📦 Deploying ${env} environment...${NC}"

    if kubectl apply -f "$file"; then
        echo -e "${GREEN}✓ ${env} application created${NC}"
    else
        echo -e "${YELLOW}⚠️  Failed to create ${env} application${NC}"
        return 1
    fi
}

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
        if [ "$ARGOCD_CLI" = true ]; then
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
echo -e "${GREEN}✅ Deployment initiated!${NC}"
echo ""
echo "Next steps:"
echo "  1. Check application status:"
if [ "$ARGOCD_CLI" = true ]; then
    echo "     argocd app list"
    echo "     argocd app get http-hello-world-dev"
else
    echo "     kubectl get applications -n argocd"
fi
echo ""
echo "  2. Access ArgoCD UI:"
echo "     kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "     Open https://localhost:8080"
echo ""
echo "  3. Get admin password:"
echo "     kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d"
echo ""
echo "  4. View application:"
echo "     kubectl get all -n dev -l app=http-hello-world"
echo "     kubectl port-forward -n dev svc/http-hello-world-dev 8080:80"
echo ""
echo -e "${BLUE}📖 For detailed instructions, see DEPLOYMENT.md${NC}"
