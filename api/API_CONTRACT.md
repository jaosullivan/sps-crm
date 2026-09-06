# SPS CRM API contract (v0.1)

Base URL: `http://localhost:8000`  
Prefix: `/api`  
Auth: `Authorization: Bearer <access_token>`  
OpenAPI: `/docs`, `/openapi.json`  

## Probes (no auth)

| Path | Use | Behavior |
|------|-----|----------|
| `GET /health` | K8s **liveness** | Process up; no DB check |
| `GET /ready` | K8s **readiness** | `SELECT 1` against Postgres; `503` if DB unreachable |

## Auth

| Method | Path | Body | Response |
|--------|------|------|----------|
| POST | `/api/auth/login` | `{ "email", "password" }` | `{ "access_token", "token_type": "bearer", "user" }` |
| GET | `/api/auth/me` | — | `UserOut` |

Seeded admin (override via env): `ADMIN_EMAIL` / `ADMIN_PASSWORD`.

Local defaults (`APP_ENV=development` only): `admin@stpatrickshk.com` / `changeme`.

## Security / deploy hygiene

- Set `APP_ENV=production` (or `prod` / `staging`) for any shared or public host.
- In those profiles the API **refuses to start** unless:
  - `JWT_SECRET` is at least 32 characters and not a known placeholder (`change-me-in-production`, `changeme`, `secret`, …)
  - `ADMIN_PASSWORD` is set and not a weak default (`changeme`, `password`, `admin`, …)
- **Rotate on every deploy:** generate a new `JWT_SECRET` (invalidates existing JWTs) and a new admin password; store only in the host secret store / `.env` (never git).
- Example: `openssl rand -hex 32`

## EKS / RDS / CORS (KAN-8)

**`DATABASE_URL` (async SQLAlchemy + asyncpg):**

```text
postgresql+asyncpg://USER:PASSWORD@HOST:5432/DBNAME?ssl=require
```

- Use the RDS endpoint as `HOST` (not in-cluster Postgres).
- URL-encode special characters in the password.
- Prefer `ssl=require` (or RDS CA bundle via `ssl` connect args) for AWS.

**CORS / same-origin nginx:**

- Preferred: ALB → nginx serves `web/dist` and proxies `/api` → API. Browser calls are same-origin; set `CORS_ORIGINS` to the public HTTPS origin anyway (e.g. `https://crm.example.com`) so direct API hits and future split origins stay safe.
- If web is on a different origin (S3+CloudFront), set `CORS_ORIGINS` to that exact HTTPS origin (comma-separated if several). Do not use `*` with credentials.

**Secrets (Secrets Manager / External Secrets):** `JWT_SECRET`, `ADMIN_PASSWORD`, `DATABASE_URL`, `CORS_ORIGINS`, `APP_ENV=production`.

## Resources (all require JWT)

CRUD pattern for each collection:

- `GET /api/{resource}` — list (`q` search where noted; deals also `stage`)
- `POST /api/{resource}` — create → `201`
- `GET /api/{resource}/{id}`
- `PATCH /api/{resource}/{id}`
- `DELETE /api/{resource}/{id}` → `204`

### Members `/api/members`

`first_name`, `last_name`, `email`, `phone?`, `company_name?`, `status` (`active` \| `lapsed` \| `complimentary`), `green_card_number?`, `joined_on?`, `notes?`

### Sponsors `/api/sponsors`

`name`, `company_id?`, `tier` (`gold` \| `silver` \| `bronze` \| `in_kind` \| `other`), `contact_name?`, `contact_email?`, `contact_phone?`, `amount_hkd?`, `year?`, `event_name?`, `starts_on?`, `ends_on?`, `notes?`

### Companies `/api/companies`

`name`, `website?`, `industry?`, `notes?`

### Deals `/api/deals`

`title`, `company_id?`, `stage` (`lead` → `contacted` → `proposal` → `won` \| `lost`), `value_hkd?`, `contact_name?`, `contact_email?`, `expected_close?`, `notes?`

Filter: `GET /api/deals?stage=proposal`

### Dashboard

`GET /api/dashboard/stats` →

```json
{
  "members_total": 0,
  "members_active": 0,
  "sponsors_total": 0,
  "companies_total": 0,
  "deals_total": 0,
  "deals_by_stage": {
    "lead": 0,
    "contacted": 0,
    "proposal": 0,
    "won": 0,
    "lost": 0
  },
  "pipeline_value_hkd": "0",
  "won_value_hkd": "0"
}
```

## Frontend notes

- Prefer JSON login (`POST /api/auth/login`) over form token URL.
- Money fields are decimals (JSON number/string); treat as HKD.
- Local CORS defaults allow Vite `http://localhost:5173`.
- Prod same-origin: relative `/api/...` is fine; see EKS / CORS above.
