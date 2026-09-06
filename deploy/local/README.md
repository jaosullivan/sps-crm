# Local cluster — Rancher Desktop first (KAN-8)

Prefer **Rancher Desktop** (local k3s + Traefik + UI). kind/k3d remain optional fallbacks.

Namespaces / URLs (Traefik is **NodePort** on this Skellig RD install — include the HTTP nodePort):

```bash
kubectl -n kube-system get svc traefik -o jsonpath='{.spec.ports[?(@.port==80)].nodePort}{"\n"}'
# example on Skellig today: 31975
```

| Namespace | Role | URL |
|-----------|------|-----|
| `cms` | CRM API + web + Postgres | **http://cms.localhost:&lt;nodePort&gt;** |
| `website` | Placeholder | **http://website.localhost:&lt;nodePort&gt;** |
| `golf` | Placeholder | **http://golf.localhost:&lt;nodePort&gt;** |

Example: http://golf.localhost:31975 · http://cms.localhost:31975

Image tags: `sps-crm-api:local`, `sps-crm-web:local`. EKS Terraform stays parked.

## Rancher Desktop (preferred)

1. Enable **Kubernetes** + default **Traefik**.
2. Container Engine **dockerd (moby)** so `docker build` images are cluster-visible.
3. kubectl context: `rancher-desktop`.

### Build + apply (kubectl)

```bash
docker build -f api/Dockerfile -t sps-crm-api:local ./api
docker build -f web/Dockerfile -t sps-crm-web:local .
kubectl apply -k deploy/kustomize/overlays/local
kubectl -n cms rollout status deploy/postgres deploy/api deploy/web
kubectl -n website rollout status deploy/website
kubectl -n golf rollout status deploy/golf
```

Use an API image that includes `GET /ready` (current `main`). Login: `admin@stpatrickshk.com` / `changeme`.

### Argo CD (monitor cms / website / golf)

See [`../argocd/README.md`](../argocd/README.md).

```bash
# after Argo CD is installed (Skellig already has argocd / argocd.local)
kubectl apply -f deploy/argocd/root-application.yaml
```

- Repo: `https://github.com/jaosullivan/sps-crm`
- App-of-Apps path: `deploy/argocd/apps`
- Child apps: `sps-cms` → `deploy/kustomize/apps/cms`, `sps-website`, `sps-golf`
- `targetRevision`: `devops/kan-8-eks-scaffold` until PR #2 merges, then `main`

Rancher UI / Argo UI both show the three apps. EKS later: same Applications, change destination cluster + image digests.

## Optional: kind / k3d

Use `kind load` / `k3d image import` + port-forward `svc/web 8080:80` if Traefik hosts are unavailable.

## Tear down

```bash
kubectl delete -k deploy/kustomize/overlays/local
# Argo: kubectl delete -f deploy/argocd/root-application.yaml
```
