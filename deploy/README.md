# SPS CRM — deploy scaffold (KAN-8)

**First path: Rancher Desktop** with namespaces `cms` / `website` / `golf`.  
kind/k3d optional. **Later:** greenfield EKS in `ap-southeast-1` (Terraform stays; **do not apply** until AWS access is confirmed).

## Layout

| Path | Purpose |
|------|--------|
| [`local/`](local/) | Rancher Desktop quickstart + Traefik `*.localhost` URLs |
| `kustomize/overlays/local/` | `cms` (API+web+Postgres), `website` + `golf`, Ingress |
| `kustomize/base` + `overlays/prod/` | EKS-oriented api/web + ALB + ExternalSecret |
| `terraform/` | VPC, EKS Fargate, RDS, ECR, Secrets Manager, IRSA hooks |
| `../api/Dockerfile` | API image → `sps-crm-api:local` |
| `../web/Dockerfile` | node→nginx → `sps-crm-web:local` |

## Local (Rancher Desktop)

Full notes: [`local/README.md`](local/README.md).

```bash
docker build -f api/Dockerfile -t sps-crm-api:local ./api
docker build -f web/Dockerfile -t sps-crm-web:local .
kubectl apply -k deploy/kustomize/overlays/local
```

Then open:

- http://cms.localhost — CRM (login `admin@stpatrickshk.com` / `changeme`)
- http://website.localhost — placeholder
- http://golf.localhost — placeholder

## EKS (later)

- Region `ap-southeast-1`, Fargate, RDS private, ECR, ALB+ACM, Secrets Manager
- **No apply yet**

### Probes / env (Backend)

- Liveness `GET /health` · Readiness `GET /ready`
- RDS: `postgresql+asyncpg://…?ssl=require` (local Postgres: no ssl)
- `APP_ENV=production` + strong secrets for real deploys

## CI (follow-up)

ECR build/push from `main` needs AWS OIDC; Actions workflow edits need `workflow` PAT scope.
