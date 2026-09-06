# SPS CRM — deploy scaffold (KAN-8)

**First path: Rancher Desktop** with namespaces `cms` / `website` / `golf` + Traefik Ingress.  
kind/k3d optional. **Later:** EKS in `ap-southeast-1` (Terraform parked — no apply yet).

## Layout

| Path | Purpose |
|------|--------|
| [`local/`](local/) | Rancher Desktop runbook, Ingress hosts, Skellig NodePorts |
| `kustomize/overlays/local/` | Stacks + Traefik Ingress (`*.localhost`) |
| `kustomize/base` + `overlays/prod/` | EKS path |
| `terraform/` | VPC / EKS / RDS / ECR / secrets |

## Local URLs

| App | Ingress | Skellig NodePort |
|-----|---------|------------------|
| CMS | http://cms.localhost | http://localhost:30390 |
| website | http://website.localhost | http://localhost:31297 |
| golf | http://golf.localhost | http://localhost:32693 |

```bash
docker build -f api/Dockerfile -t sps-crm-api:local ./api
docker build -f web/Dockerfile -t sps-crm-web:local .
kubectl apply -k deploy/kustomize/overlays/local
```

Details: [`local/README.md`](local/README.md).

## EKS (later)

No apply until AWS access is confirmed.
