# SPS CRM — AWS EKS deploy scaffold (KAN-8)

Greenfield hosting for API + web in **ap-southeast-1**. Scaffold only — **do not `terraform apply` until AWS account access is confirmed.**

## Layout

| Path | Purpose |
|------|--------|
| `terraform/` | VPC, EKS (Fargate), RDS Postgres, ECR, Secrets Manager stubs, ALB controller IRSA hooks |
| `kustomize/` | `api` + `web` (nginx static + `/api` proxy), Ingress, ExternalSecret placeholders |
| `../api/Dockerfile` | existing API image |
| `../web/Dockerfile` | optional — Frontend can add node→nginx image |

## Architecture (defaults)

- **Region:** `ap-southeast-1`
- **Compute:** EKS + **Fargate** profile (cheap/small; swap to managed NG later if needed)
- **DB:** RDS Postgres in private subnets — not in-cluster
- **Images:** ECR `sps-crm-api`, `sps-crm-web`
- **Ingress:** AWS Load Balancer Controller + ACM TLS (hostname TBD)
- **Secrets:** Secrets Manager → External Secrets Operator → K8s Secret
- **Web:** nginx serves `web/dist`, proxies `/api` → `api:8000` (same-origin; empty `VITE_API_BASE_URL`)

## Apply order (when unlocked)

1. Confirm AWS creds / account + ACM cert (or DNS for DNS-01 later).
2. `cd deploy/terraform && cp terraform.tfvars.example terraform.tfvars` — fill account, CIDRs, DB password (generated).
3. `terraform init && terraform plan` — review cost.
4. `terraform apply` — VPC → EKS/Fargate → RDS → ECR → secret stubs → IRSA roles.
5. `aws eks update-kubeconfig --region ap-southeast-1 --name <cluster>`.
6. Install AWS LB Controller + External Secrets (see `terraform/README.md` notes).
7. Build/push images to ECR; set image digests in `kustomize/overlays/prod`.
8. `kubectl apply -k deploy/kustomize/overlays/prod`.
9. Point DNS at the ALB; set `CORS_ORIGINS=https://<public-host>`.

## Cost notes (ballpark, always-on)

- EKS control plane ≈ $0.10/hr
- Fargate: pay per pod vCPU/GB (keep 2 small pods)
- RDS `db.t4g.micro` + storage
- NAT Gateway(s) often dominate — prefer 1 NAT in scaffold; accept AZ tradeoff for cost
- ALB hourly + LCU

Tear down when idle: `terraform destroy` after draining workloads.

## Probes / env (from Backend)

- Liveness: `GET /health`
- Readiness: `GET /ready` (DB `SELECT 1`)
- `DATABASE_URL=postgresql+asyncpg://USER:PASS@RDS:5432/DB?ssl=require`
- `APP_ENV=production` + strong `JWT_SECRET` / `ADMIN_PASSWORD`
- `CORS_ORIGINS` = public HTTPS origin even with same-origin nginx

## CI (follow-up)

Build/push to ECR from `main` once AWS OIDC / `workflow` PAT scope is available. Current connector is `repo`-only for Actions edits.
