# Local cluster — Rancher Desktop first (KAN-8)

Prefer **Rancher Desktop** (local k3s + Traefik + UI). kind/k3d remain optional fallbacks.

Namespaces:

| Namespace | Role | URL |
|-----------|------|-----|
| `cms` | CRM API + web + Postgres | **http://cms.localhost** |
| `website` | Placeholder | **http://website.localhost** |
| `golf` | Placeholder | **http://golf.localhost** |

Image tags stay `sps-crm-api:local` and `sps-crm-web:local`. EKS Terraform stays parked.

## Rancher Desktop (preferred)

1. Install [Rancher Desktop](https://rancherdesktop.io/), enable **Kubernetes**, keep default **Traefik** ingress.
2. In Preferences → Container Engine, **dockerd (moby)** is easiest so `docker build` images are visible to the cluster. With containerd, import via `nerdctl -n k8s.io`.
3. Point kubectl at RD: `rdctl shell` / UI → Kubernetes context `rancher-desktop`.

### Build images

```bash
# from repo root
docker build -f api/Dockerfile -t sps-crm-api:local ./api
docker build -f web/Dockerfile -t sps-crm-web:local .
```

### Apply

```bash
kubectl apply -k deploy/kustomize/overlays/local
kubectl -n cms rollout status deploy/postgres deploy/api deploy/web
kubectl -n website rollout status deploy/website
kubectl -n golf rollout status deploy/golf
```

### Open in the browser (no port-forward)

Traefik Ingress hosts (see `ingress.yaml`):

- CRM: http://cms.localhost — login `admin@stpatrickshk.com` / `changeme`
- Website placeholder: http://website.localhost
- Golf placeholder: **http://golf.localhost**

In Rancher Desktop UI: **Cluster Explorer** → Workloads / Services / Ingress → namespaces `cms`, `website`, `golf`.

Probes: `/health` + `/ready`. Local Postgres has no `ssl=require`.

### One-liner (Rancher Desktop already running)

```bash
docker build -f api/Dockerfile -t sps-crm-api:local ./api \
  && docker build -f web/Dockerfile -t sps-crm-web:local . \
  && kubectl apply -k deploy/kustomize/overlays/local \
  && kubectl -n cms rollout status deploy/postgres deploy/api deploy/web \
  && echo "Open http://cms.localhost  (golf: http://golf.localhost)"
```

## Optional: kind / k3d fallback

```bash
kind create cluster --name sps --config deploy/local/kind-config.yaml
kind load docker-image sps-crm-api:local sps-crm-web:local --name sps
kubectl apply -k deploy/kustomize/overlays/local
# Traefik hosts may not exist on kind — use:
kubectl -n cms port-forward svc/web 8080:80   # http://localhost:8080
```

k3d: `k3d cluster create sps --agents 1 -p "8080:80@loadbalancer"` then `k3d image import …`.

## Tear down

```bash
kubectl delete -k deploy/kustomize/overlays/local
# or reset Kubernetes from Rancher Desktop Preferences
```
