#!/bin/bash

# Fix ArgoCD "default project" error by deploying AppProject first

set -e

echo "🔧 Fixing ArgoCD deployment..."
echo ""

# 1. Delete existing applications if they exist (ignore errors)
echo "Cleaning up any existing applications..."
kubectl delete application http-hello-world-dev -n argocd 2>/dev/null || true
kubectl delete application http-hello-world-staging -n argocd 2>/dev/null || true
kubectl delete application http-hello-world-prod -n argocd 2>/dev/null || true

echo ""

# 2. Create the AppProject
echo "Creating ArgoCD AppProject..."
kubectl apply -f argocd/appproject.yaml

echo ""
echo "Waiting for AppProject to be ready..."
sleep 3

# 3. Now deploy the applications
echo ""
echo "You can now deploy applications using:"
echo "  ./deploy-argocd.sh"
echo ""
echo "Or manually:"
echo "  kubectl apply -f argocd/application-dev.yaml"
echo ""
echo "✅ Fix complete!"
