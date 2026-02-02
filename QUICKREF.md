# Quick Reference Card

## 📁 Repository Structure

```
.
├── README.md                    # Overview and quick start
├── DEPLOYMENT.md                # Detailed deployment guide
├── quick-start.sh              # Interactive deployment script
├── validate.sh                 # Validate Kustomize manifests
├── base/                       # Base Kubernetes manifests
│   ├── deployment.yaml         # Deployment spec
│   ├── service.yaml            # Service spec
│   ├── ingress.yaml            # Ingress spec
│   └── kustomization.yaml      # Kustomize base config
├── overlays/                   # Environment-specific configs
│   ├── dev/                    # Development (1 replica)
│   ├── staging/                # Staging (2 replicas)
│   └── production/             # Production (3+ replicas + HPA)
└── argocd/                     # ArgoCD Application manifests
    ├── application-dev.yaml    # Dev app (auto-sync)
    ├── application-staging.yaml # Staging app (auto-sync)
    └── application-prod.yaml   # Prod app (manual sync)
```

## 🚀 Quick Commands

### Deploy to ArgoCD
```bash
# Interactive deployment
./quick-start.sh

# Or manually
kubectl apply -f argocd/application-dev.yaml
```

### Validate Manifests
```bash
./validate.sh
```

### View Rendered Manifests
```bash
kubectl kustomize overlays/dev
kubectl kustomize overlays/staging
kubectl kustomize overlays/production
```

### Check Application Status
```bash
# With ArgoCD CLI
argocd app list
argocd app get http-hello-world-dev

# With kubectl
kubectl get applications -n argocd
kubectl describe application http-hello-world-dev -n argocd
```

### View Resources
```bash
kubectl get all -n dev -l app=http-hello-world
kubectl get all -n staging -l app=http-hello-world
kubectl get all -n production -l app=http-hello-world
```

### Test Application
```bash
# Port forward
kubectl port-forward -n dev svc/http-hello-world-dev 8080:80

# Test
curl http://localhost:8080
```

## 🔧 Common Operations

### Update Image Version
```bash
# Edit base/kustomization.yaml
vim base/kustomization.yaml

# Change:
# images:
#   - name: fabienfleureau/http-hello-world
#     newTag: "v2.0.0"  # <- Update this

git add base/kustomization.yaml
git commit -m "feat: update image to v2.0.0"
git push
```

### Sync Application
```bash
# Auto-sync (dev/staging) - happens automatically

# Manual sync (production)
argocd app sync http-hello-world-prod

# Or via UI
# https://localhost:8080 -> Click "Sync"
```

### Rollback
```bash
argocd app history http-hello-world-prod
argocd app rollback http-hello-world-prod <REVISION>
```

## 📊 Environment Differences

| Feature | Dev | Staging | Production |
|---------|-----|---------|------------|
| Replicas | 1 | 2 | 3 (HPA 3-10) |
| CPU Request | 50m | 100m | 200m |
| Memory Request | 32Mi | 64Mi | 128Mi |
| Auto-Sync | ✅ | ✅ | ❌ (manual) |
| Self-Heal | ✅ | ✅ | ❌ |
| Ingress Host | hello-world-dev | hello-world-staging | hello-world |

## 🔗 ArgoCD Access

```bash
# Port forward ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Login CLI
argocd login localhost:8080
```

Access: https://localhost:8080
- Username: `admin`
- Password: (from command above)

## 📝 Next Steps

1. **Push to GitHub/GitLab**
   ```bash
   git remote add origin YOUR_REPO_URL
   git push -u origin main
   ```

2. **Update Repository URL** in ArgoCD manifests:
   - Edit `argocd/application-*.yaml`
   - Replace `YOUR_USERNAME` with your actual username/org

3. **Deploy to ArgoCD**
   ```bash
   ./quick-start.sh
   ```

4. **Customize** as needed:
   - Domain names in ingress
   - Resource limits
   - Replica counts
   - Add secrets, configmaps, etc.

## 🛠️ Troubleshooting

### App won't sync
```bash
argocd app get http-hello-world-dev
argocd app refresh http-hello-world-dev --hard
```

### View events
```bash
kubectl get events -n dev --sort-by='.lastTimestamp'
```

### Check logs
```bash
kubectl logs -n dev -l app=http-hello-world -f
```

## 📚 Documentation

- **Full Guide**: See `DEPLOYMENT.md`
- **ArgoCD Docs**: https://argo-cd.readthedocs.io/
- **Kustomize Docs**: https://kustomize.io/
