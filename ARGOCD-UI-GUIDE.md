# ArgoCD UI Deployment Guide

## Deploying from ArgoCD UI

### Step 1: Create the AppProject First

**IMPORTANT:** You must create the AppProject before creating applications.

1. **Navigate to Settings → Projects** in ArgoCD UI
2. Click **"+ NEW PROJECT"**
3. Fill in the following:

   **General:**
   - **Project Name:** `http-hello-world`
   - **Description:** `HTTP Hello World Application Project`

   **Sources:**
   - Click **"ADD SOURCE"**
   - Enter: `*` (allows all repositories)
   - Or specifically: `https://github.com/fabienfleureau/argocd-test-http-server.git`

   **Destinations:**
   - Click **"ADD DESTINATION"**
   - **Server:** `https://kubernetes.default.svc` (or select your cluster)
   - **Namespace:** `*` (allows all namespaces)

   **Cluster Resource Whitelist:**
   - Click **"ADD RESOURCE"**
   - **Group:** `*`
   - **Kind:** `*`

4. Click **"CREATE"**

---

### Step 2: Create Application (Development)

1. **Navigate to Applications** (main page)
2. Click **"+ NEW APP"**
3. Fill in the following:

   **General:**
   - **Application Name:** `http-hello-world-dev`
   - **Project:** `http-hello-world` (select from dropdown)
   - **Sync Policy:** `Automatic` (check this box)
     - ☑ **Prune Resources**
     - ☑ **Self Heal**

   **Source:**
   - **Repository URL:** `https://github.com/fabienfleureau/argocd-test-http-server.git`
   - **Revision:** `main` (or `HEAD`)
   - **Path:** `overlays/dev`

   **Destination:**
   - **Cluster URL:** `https://kubernetes.default.svc` (select from dropdown)
   - **Namespace:** `dev`

   **Directory/Kustomize (should auto-detect):**
   - This will be detected automatically since we use Kustomize

4. Click **"CREATE"**

---

### Step 3: Create Application (Staging) - Optional

Same as above, but with these changes:
- **Application Name:** `http-hello-world-staging`
- **Path:** `overlays/staging`
- **Namespace:** `staging`

---

### Step 4: Create Application (Production) - Optional

Same as above, but with these changes:
- **Application Name:** `http-hello-world-prod`
- **Path:** `overlays/production`
- **Namespace:** `production`
- **Sync Policy:** `Manual` (uncheck Automatic for production safety)

---

## Quick Reference: UI Field Values

### For Development Environment

```
┌─────────────────────────────────────────────────────┐
│ General                                             │
├─────────────────────────────────────────────────────┤
│ Application Name:  http-hello-world-dev             │
│ Project:          http-hello-world                  │
│ Sync Policy:      Automatic                         │
│   ☑ Prune Resources                                 │
│   ☑ Self Heal                                       │
├─────────────────────────────────────────────────────┤
│ Source                                              │
├─────────────────────────────────────────────────────┤
│ Repository URL:                                     │
│   https://github.com/fabienfleureau/                │
│   argocd-test-http-server.git                       │
│ Revision:         main                              │
│ Path:             overlays/dev                      │
├─────────────────────────────────────────────────────┤
│ Destination                                         │
├─────────────────────────────────────────────────────┤
│ Cluster URL:      https://kubernetes.default.svc    │
│ Namespace:        dev                               │
└─────────────────────────────────────────────────────┘
```

---

## Screenshots Guide (What to Click)

### Creating AppProject

1. **Settings** (gear icon in left sidebar)
2. **Projects** (in Settings menu)
3. **+ NEW PROJECT** (top right button)
4. Fill form as described above
5. **CREATE** (bottom of form)

### Creating Application

1. **Applications** (grid icon in left sidebar)
2. **+ NEW APP** (top left button)
3. Fill form as described above
4. **CREATE** (top of form)

---

## Troubleshooting UI Issues

### "Project 'http-hello-world' does not exist"

**Solution:** Create the AppProject first (see Step 1 above)

### Can't find "http-hello-world" in Project dropdown

**Solution:**
1. Refresh the page
2. Or manually type `http-hello-world` in the Project field
3. Or create the AppProject via kubectl:
   ```bash
   kubectl apply -f argocd/appproject.yaml
   ```
   Then refresh the ArgoCD UI

### Repository shows as "Unknown" or won't connect

**Solution:**
1. Go to **Settings → Repositories**
2. Click **"CONNECT REPO"**
3. Connection method: **VIA HTTPS**
4. Repository URL: `https://github.com/fabienfleureau/argocd-test-http-server.git`
5. Click **"CONNECT"**

### Path not found or "directory does not exist"

**Solution:**
- Ensure the path is exactly: `overlays/dev` (no leading/trailing slashes)
- Verify the repository and branch are correct
- Check the repository has been pushed to GitHub

### Namespace doesn't exist

**Solution:**
- Check **"AUTO-CREATE NAMESPACE"** in Sync Options
- Or manually create namespace:
  ```bash
  kubectl create namespace dev
  ```

---

## Alternative: Use UI + Manifest YAML

Instead of filling the form, you can paste YAML directly:

1. Click **"+ NEW APP"**
2. Click **"EDIT AS YAML"** (top right toggle)
3. Paste this for dev environment:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: http-hello-world-dev
spec:
  project: http-hello-world
  source:
    repoURL: https://github.com/fabienfleureau/argocd-test-http-server.git
    targetRevision: main
    path: overlays/dev
  destination:
    server: https://kubernetes.default.svc
    namespace: dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

4. Click **"SAVE"**
5. Click **"CREATE"**

---

## Verification

After creating the application:

1. You should see the application card on the main page
2. Status should show:
   - **Sync Status:** Synced (or Syncing)
   - **Health Status:** Healthy (after a few moments)
3. Click on the application card to see the resource tree
4. All resources (Deployment, Service, Ingress) should be green

---

## Need Help?

If you still get errors:
1. Take a screenshot of the error
2. Check the **TROUBLESHOOTING.md** file in this repository
3. Or verify AppProject exists:
   ```bash
   kubectl get appproject http-hello-world -n argocd
   ```
