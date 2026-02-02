# Troubleshooting Guide

## Common Issues and Solutions

### Error: "app is not allowed in project 'default', or the project does not exist"

**Cause:** ArgoCD requires applications to be associated with a project, but the "default" project may not exist or may have restrictions.

**Solution:**

**Quick Fix:**
```bash
./fix-project-error.sh
```

**Manual Fix:**

1. **Create the AppProject first:**
   ```bash
   kubectl apply -f argocd/appproject.yaml
   ```

2. **If you already created applications with the wrong project, delete them:**
   ```bash
   kubectl delete application http-hello-world-dev -n argocd
   kubectl delete application http-hello-world-staging -n argocd
   kubectl delete application http-hello-world-prod -n argocd
   ```

3. **Re-create the applications:**
   ```bash
   kubectl apply -f argocd/application-dev.yaml
   kubectl apply -f argocd/application-staging.yaml
   kubectl apply -f argocd/application-prod.yaml
   ```

**Verify:**
```bash
# Check AppProject exists
kubectl get appproject -n argocd

# Check applications
kubectl get applications -n argocd
```

---

### Error: "rpc error: code = Unknown desc = Manifest generation error"

**Cause:** Invalid Kustomize manifests or repository issues.

**Solution:**

1. **Validate manifests locally:**
   ```bash
   ./validate.sh
   ```

2. **Check specific overlay:**
   ```bash
   kubectl kustomize overlays/dev
   kubectl kustomize overlays/staging
   kubectl kustomize overlays/production
   ```

3. **Verify repository URL is correct** in application manifests.

4. **Refresh the application:**
   ```bash
   argocd app refresh http-hello-world-dev --hard
   ```

---

### Error: "repository not found"

**Cause:** ArgoCD cannot access the Git repository.

**Solution:**

1. **For public repositories:**
   - Verify the URL is correct in `argocd/application-*.yaml`
   - Check the repository is public and accessible

2. **For private repositories:**
   ```bash
   argocd repo add https://github.com/YOUR_USERNAME/REPO.git \
     --username YOUR_USERNAME \
     --password YOUR_GITHUB_TOKEN
   ```

3. **Update repository URL in manifests if needed:**
   ```bash
   # Update all application files
   sed -i 's|OLD_REPO_URL|NEW_REPO_URL|g' argocd/application-*.yaml
   git add argocd/
   git commit -m "fix: update repository URL"
   git push
   ```

---

### Error: "context deadline exceeded"

**Cause:** ArgoCD cannot reach the target cluster or namespace creation timeout.

**Solution:**

1. **Check cluster connectivity:**
   ```bash
   kubectl cluster-info
   kubectl get nodes
   ```

2. **Verify namespace exists or can be created:**
   ```bash
   kubectl get namespace dev
   kubectl get namespace staging
   kubectl get namespace production
   ```

3. **Manually create namespaces if needed:**
   ```bash
   kubectl create namespace dev
   kubectl create namespace staging
   kubectl create namespace production
   ```

---

### Application is "OutOfSync" but won't sync

**Cause:** Various issues like resource conflicts, invalid manifests, or sync policies.

**Solution:**

1. **Check sync status:**
   ```bash
   argocd app get http-hello-world-dev
   ```

2. **View detailed diff:**
   ```bash
   argocd app diff http-hello-world-dev
   ```

3. **Force refresh:**
   ```bash
   argocd app refresh http-hello-world-dev --hard
   ```

4. **Manually trigger sync:**
   ```bash
   argocd app sync http-hello-world-dev
   ```

5. **If resources exist from previous deployments:**
   ```bash
   # Delete and re-create
   kubectl delete -k overlays/dev
   argocd app sync http-hello-world-dev
   ```

---

### Application is "Degraded" or "Progressing"

**Cause:** Pods failing to start, health checks failing, or resources not ready.

**Solution:**

1. **Check application health:**
   ```bash
   argocd app get http-hello-world-dev
   ```

2. **Check pod status:**
   ```bash
   kubectl get pods -n dev -l app=http-hello-world
   kubectl describe pod -n dev -l app=http-hello-world
   ```

3. **View pod logs:**
   ```bash
   kubectl logs -n dev -l app=http-hello-world -f
   ```

4. **Check events:**
   ```bash
   kubectl get events -n dev --sort-by='.lastTimestamp'
   ```

5. **Common issues:**
   - **Image pull errors:** Check image name and registry access
   - **Resource limits:** Pods may need more resources
   - **Health check failures:** Check liveness/readiness probe settings

---

### Cannot access ArgoCD UI

**Cause:** Port-forward not running or incorrect password.

**Solution:**

1. **Start port-forward:**
   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   ```

2. **Get admin password:**
   ```bash
   kubectl -n argocd get secret argocd-initial-admin-secret \
     -o jsonpath="{.data.password}" | base64 -d && echo
   ```

3. **Reset admin password if needed:**
   ```bash
   # Set new password
   argocd account update-password

   # Or via kubectl
   kubectl -n argocd patch secret argocd-secret \
     -p '{"stringData": {"admin.password": "'$(htpasswd -nbBC 10 "" NEW_PASSWORD | tr -d ':\n' | sed 's/$2y/$2a/')'"}}'
   ```

---

### Kustomize validation errors

**Cause:** Invalid YAML syntax or Kustomize configuration issues.

**Solution:**

1. **Run validation script:**
   ```bash
   ./validate.sh
   ```

2. **Check specific overlay:**
   ```bash
   kubectl kustomize overlays/dev 2>&1 | head -20
   ```

3. **Common fixes:**
   - Check indentation (use spaces, not tabs)
   - Verify all referenced files exist
   - Ensure `bases` or `resources` paths are correct
   - Validate YAML syntax with `yamllint`

---

### Image pull errors (ImagePullBackOff, ErrImagePull)

**Cause:** Cannot pull Docker image from registry.

**Solution:**

1. **Verify image exists:**
   ```bash
   docker pull fabienfleureau/http-hello-world:latest
   ```

2. **Check image name in manifests:**
   ```bash
   grep "image:" base/deployment.yaml
   grep "newTag:" base/kustomization.yaml
   ```

3. **For private registries, create imagePullSecret:**
   ```bash
   kubectl create secret docker-registry regcred \
     --docker-server=REGISTRY_URL \
     --docker-username=USERNAME \
     --docker-password=PASSWORD \
     -n dev
   ```

4. **Add imagePullSecrets to deployment** if needed.

---

### HPA warnings (unable to get metrics)

**Cause:** Metrics Server not installed or not working.

**Solution:**

1. **Check if Metrics Server is installed:**
   ```bash
   kubectl get deployment metrics-server -n kube-system
   ```

2. **Install Metrics Server if missing:**
   ```bash
   kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
   ```

3. **Verify metrics are available:**
   ```bash
   kubectl top nodes
   kubectl top pods -n production
   ```

4. **If HPA is not critical, you can disable it** by removing `hpa.yaml` from production overlay.

---

## Verification Commands

### Check Everything

```bash
# ArgoCD status
kubectl get all -n argocd

# AppProject
kubectl get appproject -n argocd

# Applications
kubectl get applications -n argocd
argocd app list

# Deployed resources
kubectl get all -n dev -l app=http-hello-world
kubectl get all -n staging -l app=http-hello-world
kubectl get all -n production -l app=http-hello-world

# Ingress
kubectl get ingress -A
```

### Full Diagnostic

```bash
# Save to file for review
cat > diagnostic.sh << 'EOF'
#!/bin/bash
echo "=== ArgoCD Status ==="
kubectl get all -n argocd

echo -e "\n=== AppProject ==="
kubectl get appproject -n argocd -o yaml

echo -e "\n=== Applications ==="
kubectl get applications -n argocd

echo -e "\n=== Dev Environment ==="
kubectl get all -n dev

echo -e "\n=== Recent Events ==="
kubectl get events -n dev --sort-by='.lastTimestamp' | tail -20
EOF

chmod +x diagnostic.sh
./diagnostic.sh
```

---

## Getting Help

1. **View ArgoCD logs:**
   ```bash
   kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server -f
   ```

2. **View application events:**
   ```bash
   kubectl describe application http-hello-world-dev -n argocd
   ```

3. **Check ArgoCD documentation:**
   - https://argo-cd.readthedocs.io/

4. **Enable verbose logging:**
   ```bash
   argocd app sync http-hello-world-dev --loglevel debug
   ```
