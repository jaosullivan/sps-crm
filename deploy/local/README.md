# Local cluster — Rancher Desktop first (KAN-8)

Prefer **Rancher Desktop** (k3s + Traefik + UI). kind/k3d remain optional fallbacks.

| Namespace | Role | Ingress host | Skellig NodePort today |
|-----------|------|--------------|------------------------|
| `cms` | CRM API + web + Postgres | **http://cms.localhost** | http://localhost:30390 |
| `website` | Placeholder | **http://website.localhost** | http://localhost:31297 |
| `golf` | Placeholder | **http://golf.localhost** | http://localhost:32693 |

Images: `sps-crm-api:local`, `sps-crm-web:local`.

Argo CD on Skellig: https://localhost:32675 (apps `sps-crm-local`, `spshk-production-app`).

## Rancher Desktop (preferred)

1. Enable Kubernetes + Traefik; container engine **dockerd (moby)**.
2. kubectl context: `rancher-desktop`.
3. Build + apply:

```bash
docker build -f api/Dockerfile -t sps-crm-api:local ./api
docker build -f web/Dockerfile -t sps-crm-web:local .
kubectl apply -k deploy/kustomize/overlays/local
kubectl -n cms rollout status deploy/postgres deploy/api deploy/web
kubectl -n website rollout status deploy/website
kubectl -n golf rollout status deploy/golf
```

### How to open apps

**Ingress hosts** (this PR — Traefik `ingressClassName: traefik`):

- http://cms.localhost — login `admin@stpatrickshk.com` / `changeme`
- http://website.localhost
- http://golf.localhost

If `*.localhost` on port 80 is refused, Traefik is exposed as NodePort — append Traefik’s HTTP nodePort:

```bash
kubectl -n kube-system get svc traefik -o jsonpath='{.spec.ports[?(@.port==80)].nodePort}{"\n"}'
# e.g. http://cms.localhost:<nodePort>  and http://golf.localhost:<nodePort>
```

**Service NodePorts** (already published on Skellig without Ingress):

- CMS web: http://localhost:30390
- website: http://localhost:31297
- golf: **http://localhost:32693**

In Rancher UI: Cluster Explorer → namespaces `cms` / `website` / `golf` → Services / Ingress.

API image must include `GET /ready` (current `main`). Local Postgres has no `ssl=require`.

## Optional: kind / k3d

```bash
kind create cluster --name sps --config deploy/local/kind-config.yaml
kind load docker-image sps-crm-api:local sps-crm-web:local --name sps
kubectl apply -k deploy/kustomize/overlays/local
kubectl -n cms port-forward svc/web 8080:80   # http://localhost:8080
```

## Tear down

```bash
kubectl delete -k deploy/kustomize/overlays/local
```
