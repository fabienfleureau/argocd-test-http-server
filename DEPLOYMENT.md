---
# ArgoCD Deployment Guide

## Prerequisites

1. **Kubernetes Cluster**: Running cluster with kubectl access
2. **ArgoCD Installed**:
   ```bash
   kubectl create namespace argocd
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   ```
3. **ArgoCD CLI** (optional but recommended):
   ```bash
   # macOS
   brew install argocd

   # Linux
   curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
   sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
   ```

## Setup Steps

### 1. Access ArgoCD UI

```bash
# Port forward to access UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Login via CLI
argocd login localhost:8080
```

Access UI at: https://localhost:8080
- Username: `admin`
- Password: (from command above)

### 2. Configure Repository

**Option A: Public Repository (Recommended for this demo)**
```bash
argocd repo add https://github.com/YOUR_USERNAME/http-hello-world-argocd.git
```

**Option B: Private Repository**
```bash
argocd repo add https://github.com/YOUR_USERNAME/http-hello-world-argocd.git \
  --username YOUR_USERNAME \
  --password YOUR_GITHUB_TOKEN
```

### 3. Deploy Applications

#### Development Environment
```bash
kubectl apply -f argocd/application-dev.yaml

# Or via CLI
argocd app create http-hello-world-dev \
  --repo https://github.com/YOUR_USERNAME/http-hello-world-argocd.git \
  --path overlays/dev \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace dev \
  --sync-policy automated \
  --auto-prune \
  --self-heal
```

#### Staging Environment
```bash
kubectl apply -f argocd/application-staging.yaml
```

#### Production Environment (Manual Sync)
```bash
kubectl apply -f argocd/application-prod.yaml

# Manually sync when ready
argocd app sync http-hello-world-prod
```

### 4. Verify Deployment

```bash
# Check application status
argocd app list
argocd app get http-hello-world-dev

# Check Kubernetes resources
kubectl get all -n dev -l app=http-hello-world

# Test the application
kubectl port-forward -n dev svc/http-hello-world-dev 8080:80
curl http://localhost:8080
```

## Application Management

### Sync Applications

```bash
# Sync a specific app
argocd app sync http-hello-world-dev

# Sync all apps
argocd app sync --all
```

### View Application Details

```bash
# Application info
argocd app get http-hello-world-dev

# View sync history
argocd app history http-hello-world-dev

# View logs
argocd app logs http-hello-world-dev
```

### Rollback

```bash
# List history
argocd app history http-hello-world-dev

# Rollback to specific revision
argocd app rollback http-hello-world-dev <REVISION_ID>
```

### Delete Application

```bash
# Delete app (keeps resources)
argocd app delete http-hello-world-dev

# Delete app and resources
argocd app delete http-hello-world-dev --cascade
```

## Updating the Application

### Change Image Version

1. Edit `base/kustomization.yaml`:
   ```yaml
   images:
     - name: fabienfleureau/http-hello-world
       newTag: "v2.0.0"  # Change version here
   ```

2. Commit and push:
   ```bash
   git add base/kustomization.yaml
   git commit -m "feat: update image to v2.0.0"
   git push
   ```

3. ArgoCD will automatically sync (dev/staging) or wait for manual sync (prod)

### Modify Resources

1. Edit environment-specific overlay files in `overlays/{dev,staging,production}/`
2. Commit and push changes
3. ArgoCD syncs automatically or manually

## Monitoring

### ArgoCD UI
- **Application Health**: Shows if resources are healthy
- **Sync Status**: Shows if app is in sync with Git
- **Resource Tree**: Visual representation of all resources

### CLI Monitoring

```bash
# Watch sync status
watch argocd app get http-hello-world-dev

# View events
kubectl get events -n dev --sort-by='.lastTimestamp'

# View pod logs
kubectl logs -n dev -l app=http-hello-world -f
```

## Troubleshooting

### Application Won't Sync

```bash
# Check application status
argocd app get http-hello-world-dev

# Force refresh
argocd app refresh http-hello-world-dev

# Hard refresh (ignore cache)
argocd app refresh http-hello-world-dev --hard
```

### Invalid Manifests

```bash
# Validate Kustomize locally
kubectl kustomize overlays/dev

# Diff against cluster
argocd app diff http-hello-world-dev
```

### Access ArgoCD Server

```bash
# Reset admin password
kubectl -n argocd patch secret argocd-secret \
  -p '{"stringData": {"admin.password": "'$(htpasswd -nbBC 10 "" YOUR_PASSWORD | tr -d ':\n' | sed 's/$2y/$2a/')'"}}'
```

## Best Practices

1. **Use Separate Repos for Different Environments** (enterprise setup)
2. **Tag Production Images** - Don't use `latest` in production
3. **Manual Sync for Production** - Require approval before production changes
4. **Enable Auto-Prune with Caution** - Test in dev/staging first
5. **Monitor Application Health** - Set up alerts for degraded applications
6. **Use Projects** - Organize apps into ArgoCD projects for better RBAC
7. **GitOps Workflow** - All changes through Git, no manual kubectl applies

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Update Image Tag

on:
  push:
    tags:
      - 'v*'

jobs:
  update-manifests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Update image tag
        run: |
          TAG=${GITHUB_REF#refs/tags/}
          cd base
          kustomize edit set image fabienfleureau/http-hello-world:$TAG

      - name: Commit changes
        run: |
          git config user.name "GitHub Actions"
          git config user.email "actions@github.com"
          git add base/kustomization.yaml
          git commit -m "chore: update image to $TAG"
          git push
```

## Additional Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Kustomize Documentation](https://kustomize.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
