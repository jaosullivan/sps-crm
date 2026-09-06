# Argo CD — local Rancher Desktop

Skellig today:

- UI: https://localhost:32675
- Cluster secret: `rancher-desktop`
- App `sps-crm-local` → `deploy/kustomize/overlays/local` on `main` (Synced/Healthy)
- Traefik hosts via `:31975` — `cms|website|golf.localhost`

## Manifests in this folder

| File | Purpose |
|------|--------|
| `sps-crm-local.yaml` | Single Application for the whole local overlay (matches live app) |
| `root-application.yaml` | Optional App-of-Apps entrypoint |
| `apps/` | Child Applications `sps-cms` / `sps-website` / `sps-golf` (split paths; use when/if overlay is split) |

Repo: `https://github.com/jaosullivan/sps-crm`

## Apply (after merge to main)

```bash
# idempotent with the live app name:
kubectl apply -f deploy/argocd/sps-crm-local.yaml

# optional App-of-Apps (only if you want child apps instead of/in addition to sps-crm-local):
kubectl apply -f deploy/argocd/root-application.yaml
```

Do not double-sync the same resources with both `sps-crm-local` and the three child apps unless paths are split.

## EKS later

Clone `sps-crm-local` → change destination cluster + path `deploy/kustomize/overlays/prod` + ECR images.
