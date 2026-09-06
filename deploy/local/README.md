# Local kind / k3d (KAN-8 first path)

Run SPS CRM on a local cluster **before** any EKS apply. Three namespaces:

| Namespace | Role |
|-----------|------|
| `cms` | CRM API + web (nginx same-origin `/api`) + Postgres |
| `website` | Placeholder Deployment (public site slot) |
| `golf` | Placeholder Deployment (golf app slot) |

EKS Terraform under `../terraform/` stays for later — do not apply until AWS access is confirmed.

## One-liner (kind + cms smoke)

From repo root (after `web/Dockerfile` is on main):

```bash
kind create cluster --name sps --config deploy/local/kind-config.yaml \
  && docker build -f api/Dockerfile -t sps-crm-api:local ./api \
  && docker build -f web/Dockerfile -t sps-crm-web:local . \
  && kind load docker-image sps-crm-api:local sps-crm-web:local --name sps \
  && kubectl apply -k deploy/kustomize/overlays/local \
  && kubectl -n cms rollout status deploy/postgres deploy/api deploy/web \
  && kubectl -n cms port-forward svc/web 8080:80
```

Then open http://localhost:8080 — login `admin@stpatrickshk.com` / `changeme`. Probes: `/health` + `/ready`. Local Postgres has no `ssl=require` (RDS-only later).

`website` / `golf` stay nginx placeholders.

## Prerequisites

- Docker, kind (or k3d), kubectl

## kind / k3d (stepwise)

```bash
kind create cluster --name sps --config deploy/local/kind-config.yaml
# k3d: k3d cluster create sps --agents 1 -p "8080:80@loadbalancer"
```

### Build + load

```bash
docker build -f api/Dockerfile -t sps-crm-api:local ./api
docker build -f web/Dockerfile -t sps-crm-web:local .   # repo root
kind load docker-image sps-crm-api:local sps-crm-web:local --name sps
# k3d: k3d image import sps-crm-api:local sps-crm-web:local -c sps
```

### Apply

```bash
kubectl apply -k deploy/kustomize/overlays/local
kubectl -n cms rollout status deploy/api deploy/web deploy/postgres
kubectl -n website rollout status deploy/website
kubectl -n golf rollout status deploy/golf
kubectl -n cms port-forward svc/web 8080:80
```

## Tear down

```bash
kind delete cluster --name sps
# or: k3d cluster delete sps
```
