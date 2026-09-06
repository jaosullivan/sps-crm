# Local kind / k3d (KAN-8 first path)

Run SPS CRM on a local cluster **before** any EKS apply. Three namespaces:

| Namespace | Role |
|-----------|------|
| `cms` | CRM API + web (nginx same-origin `/api`) + Postgres |
| `website` | Placeholder Deployment (public site slot) |
| `golf` | Placeholder Deployment (golf app slot) |

EKS Terraform under `../terraform/` stays for later — do not apply until AWS access is confirmed.

## Prerequisites

- Docker
- [kind](https://kind.sigs.k8s.io/) **or** [k3d](https://k3d.io/)
- `kubectl`
- Optional: build `web/Dockerfile` from @Frontend Dev (falls back to `nginx:alpine` placeholder if missing)

## kind

```bash
kind create cluster --name sps --config deploy/local/kind-config.yaml
# load images into the nodes after build:
#   kind load docker-image sps-crm-api:local sps-crm-web:local --name sps
```

## k3d

```bash
k3d cluster create sps --agents 1 -p "8080:80@loadbalancer"
# k3d image import sps-crm-api:local sps-crm-web:local -c sps
```

## Build images

```bash
docker build -t sps-crm-api:local ./api
docker build -t sps-crm-web:local ./web   # needs web/Dockerfile
```

## Apply

```bash
kubectl apply -k deploy/kustomize/overlays/local
kubectl -n cms rollout status deploy/api deploy/web deploy/postgres
kubectl -n website rollout status deploy/website
kubectl -n golf rollout status deploy/golf
```

Port-forward CRM:

```bash
kubectl -n cms port-forward svc/web 8080:80
# open http://localhost:8080  (API via same-origin /api)
# seed admin: admin@stpatrickshk.com / changeme (APP_ENV=development)
```

## Tear down

```bash
kind delete cluster --name sps
# or: k3d cluster delete sps
```
