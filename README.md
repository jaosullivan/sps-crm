# SPS CRM

St. Patrick's Society HK CRM — members, sponsors, companies, and deals.

Stack: FastAPI + SQLAlchemy async + Postgres · React/Vite/TypeScript (Radix/shadcn-style).

## Quick start

### 1. API + Postgres

```bash
cp .env.example .env
docker compose up --build -d
```

- API: http://localhost:8000
- OpenAPI: http://localhost:8000/docs
- Health: http://localhost:8000/health
- Seeded admin: `ADMIN_EMAIL` / `ADMIN_PASSWORD` from `.env` (defaults `admin@stpatrickshk.com` / `changeme`)

Compose brings up `db` (Postgres 16) and `api`. Tables + seed run on API startup.

For local API without Compose, use `api/.env.example` (`DATABASE_URL` host `localhost`) and run Postgres yourself.

### 2. Frontend

```bash
cd web
cp .env.example .env   # if present
npm install
npm run dev
```

App: http://localhost:5173 — CORS defaults allow that origin.

### MVP check

1. `docker compose up --build -d`
2. `cd web && npm install && npm run dev`
3. Log in with seeded admin
4. Manage members, sponsors, and deals

## Layout

| Path | Owner |
|------|--------|
| `api/` | Backend — models, JWT auth, REST, OpenAPI, seed |
| `web/` | Frontend — app shell, auth, CRUD, dashboard |
| `docker-compose.yml` | DevOps — Postgres + API |
| `.github/workflows/ci.yml` | DevOps — lint / import / build |

API contract: [`api/API_CONTRACT.md`](api/API_CONTRACT.md)

## Env (no secrets in git)

Root `.env.example` is for Compose. Key vars:

- `DATABASE_URL` — async Postgres URL (`@db` in Compose, `@localhost` for host runs)
- `JWT_SECRET`
- `CORS_ORIGINS` — comma-separated
- `ADMIN_EMAIL` / `ADMIN_PASSWORD` / `ADMIN_FULL_NAME`

## CI

On push/PR to `main`:

- API: install deps, import `app.main`, build Docker image
- Web: lint + build when `web/package.json` exists
- Compose: `docker compose config` validation

## Ops notes

- Healthchecks: Postgres `pg_isready`; API `GET /health`
- Do not commit `.env` (gitignored). Rotate `JWT_SECRET` and admin password before any real deploy.
