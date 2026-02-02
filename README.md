# HTTP Hello World - ArgoCD Deployment

This repository contains Kubernetes manifests for deploying the `fabienfleureau/http-hello-world` Docker image using ArgoCD.

## Repository Structure

```
.
├── README.md                    # This file
├── base/                        # Base Kubernetes manifests
│   ├── kustomization.yaml      # Kustomize configuration
│   ├── deployment.yaml         # Deployment specification
│   ├── service.yaml            # Service specification
│   └── ingress.yaml            # Ingress specification (optional)
└── overlays/                   # Environment-specific overlays
    ├── dev/                    # Development environment
    │   └── kustomization.yaml
    ├── staging/                # Staging environment
    │   └── kustomization.yaml
    └── production/             # Production environment
        └── kustomization.yaml
```

## Quick Start

### Prerequisites

- Kubernetes cluster
- ArgoCD installed on the cluster
- kubectl configured

### Deploy with ArgoCD

1. **Create ArgoCD Application (using kubectl):**

```bash
kubectl apply -f argocd/application.yaml
```

2. **Or use ArgoCD CLI:**

```bash
argocd app create http-hello-world \
  --repo https://github.com/YOUR_USERNAME/http-hello-world-argocd.git \
  --path overlays/dev \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default \
  --sync-policy automated
```

3. **Sync the application:**

```bash
argocd app sync http-hello-world
```

### Manual Deployment (without ArgoCD)

```bash
# Development
kubectl apply -k overlays/dev

# Staging
kubectl apply -k overlays/staging

# Production
kubectl apply -k overlays/production
```

## Configuration

### Environments

- **Dev**: 1 replica, minimal resources
- **Staging**: 2 replicas, moderate resources
- **Production**: 3 replicas, production-grade resources with autoscaling

### Accessing the Application

After deployment, access the application:

```bash
# Port-forward to test locally
kubectl port-forward svc/http-hello-world 8080:80

# Then visit http://localhost:8080
```

If using Ingress:
```bash
# Check ingress
kubectl get ingress http-hello-world

# Access via configured domain
curl http://hello-world.example.com
```

## ArgoCD Features

This repository is configured to leverage:

- **Automated Sync**: Changes pushed to this repo are automatically deployed
- **Self-Healing**: ArgoCD will revert manual changes to match Git state
- **Pruning**: Removed resources in Git are deleted from the cluster
- **Health Checks**: ArgoCD monitors application health
- **Rollback**: Easy rollback to previous Git commits

## Customization

### Update Image Version

Edit `base/kustomization.yaml`:

```yaml
images:
  - name: fabienfleureau/http-hello-world
    newTag: "your-version"
```

### Modify Resources

Edit overlay-specific `kustomization.yaml` files to adjust:
- Replica counts
- Resource limits
- Environment variables

## Monitoring

Check application status:

```bash
# ArgoCD UI
argocd app get http-hello-world

# Kubernetes resources
kubectl get all -l app=http-hello-world
```

## License

MIT
