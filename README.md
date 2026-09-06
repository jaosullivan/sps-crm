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
- Seeded admin: `admin@stpatrickshk.com` / `changeme` (override via `ADMIN_EMAIL` / `ADMIN_PASSWORD`)

Compose brings up `db` (Postgres 16) and `api`. Tables + seed run on API startup.

For local API without Compose, use `api/.env.example` (`DATABASE_URL` host `localhost`) and run Postgres yourself.

### 2. Frontend

```bash
cd web
cp .env.example .env
npm install
npm run dev
```

Or one-liner (no `.env` file):

```bash
cd web && npm install && VITE_API_BASE_URL=http://localhost:8000 npm run dev
```

- App: http://localhost:5173
- API base: `VITE_API_BASE_URL=http://localhost:8000` (see `web/.env.example`)
- CORS already allows Vite on `:5173`

### MVP check

1. `docker compose up --build -d`
2. `cd web && npm install && VITE_API_BASE_URL=http://localhost:8000 npm run dev`
3. Open http://localhost:5173 and log in as `admin@stpatrickshk.com` / `changeme`
4. Manage members, sponsors, companies, and deals

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

Frontend (`web/.env.example`):

- `VITE_API_BASE_URL` — default `http://localhost:8000`

## CI

On push/PR to `main`:

- API: install deps, import `app.main`, build Docker image
- Web: lint + build when `web/package.json` exists
- Compose: `docker compose config` validation

## Ops notes

- Healthchecks: Postgres `pg_isready`; API `GET /health`
- Do not commit `.env` (gitignored). Rotate `JWT_SECRET` and admin password before any real deploy.
