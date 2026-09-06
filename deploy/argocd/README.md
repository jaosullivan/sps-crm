# Argo CD (local Rancher Desktop → EKS later)

Monitor `cms` / `website` / `golf` with Argo CD. Skellig’s cluster already had an `argocd` Ingress (`argocd.local`); use that install or helm below.

## Repo

- GitHub: `https://github.com/jaosullivan/sps-crm`
- Manifests: `deploy/kustomize/apps/{cms,website,golf}`
- App-of-Apps: `deploy/argocd/`
- Target revision: `devops/kan-8-eks-scaffold` until merged; then `main`

## Install (if needed)

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
# UI: port-forward or Traefik host (this cluster: argocd.local + Traefik NodePort)
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

Register the repo (public today — no creds):

```bash
argocd repo add https://github.com/jaosullivan/sps-crm
```

## App of Apps

```bash
kubectl apply -f deploy/argocd/root-application.yaml
# or: argocd app create -f deploy/argocd/root-application.yaml
```

`root-application` syncs `deploy/argocd/apps`, which defines three Applications:

| App | Path | Namespace |
|-----|------|-----------|
| `sps-cms` | `deploy/kustomize/apps/cms` | `cms` |
| `sps-website` | `deploy/kustomize/apps/website` | `website` |
| `sps-golf` | `deploy/kustomize/apps/golf` | `golf` |

Build/push `sps-crm-api:local` + `sps-crm-web:local` before syncing CMS (images are `IfNotPresent`).

## EKS later

Point Applications at `deploy/kustomize/overlays/prod` (or a future `apps/*/overlays/eks`) and the ECR image digests. Same App-of-Apps pattern; change `repoURL` / `targetRevision` / cluster destination only.
