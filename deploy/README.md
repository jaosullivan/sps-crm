# SPS CRM — deploy scaffold (KAN-8)

**First path: local kind/k3d** with namespaces `cms` / `website` / `golf`.  
**Later path:** greenfield EKS in `ap-southeast-1` (Terraform stays; **do not apply** until AWS access is confirmed).

## Layout

| Path | Purpose |
|------|--------|
| [`local/`](local/) | kind/k3d quickstart + **one-liner** |
| `kustomize/overlays/local/` | `cms` (API+web+Postgres), `website` + `golf` placeholder Deployments |
| `kustomize/base` + `overlays/prod/` | EKS-oriented api/web + ALB + ExternalSecret |
| `terraform/` | VPC, EKS Fargate, RDS, ECR, Secrets Manager, IRSA hooks |
| `../api/Dockerfile` | API image |
| `../web/Dockerfile` | node→nginx (Frontend) |

## Local (do this first)

Full notes: [`local/README.md`](local/README.md).

```bash
kind create cluster --name sps --config deploy/local/kind-config.yaml \
  && docker build -f api/Dockerfile -t sps-crm-api:local ./api \
  && docker build -f web/Dockerfile -t sps-crm-web:local . \
  && kind load docker-image sps-crm-api:local sps-crm-web:local --name sps \
  && kubectl apply -k deploy/kustomize/overlays/local \
  && kubectl -n cms port-forward svc/web 8080:80
```

- `cms` — CRM stack (liveness `/health`, readiness `/ready`, same-origin `/api`)
- `website` / `golf` — nginx placeholder Deployments

## EKS (later)

- Region `ap-southeast-1`, Fargate, RDS private, ECR, ALB+ACM, Secrets Manager
- Apply order and cost notes: keep reviewing `terraform/` — **no apply yet**
- Prod charts: `kubectl apply -k deploy/kustomize/overlays/prod` after images + secrets

### Probes / env (Backend)

- Liveness `GET /health` · Readiness `GET /ready`
- RDS: `postgresql+asyncpg://USER:PASS@HOST:5432/DB?ssl=require`
- `APP_ENV=production` + strong secrets; `CORS_ORIGINS` = public HTTPS origin
- Local kind Postgres: no `ssl=require`

## CI (follow-up)

ECR build/push from `main` needs AWS OIDC; Actions workflow edits need `workflow` PAT scope.
