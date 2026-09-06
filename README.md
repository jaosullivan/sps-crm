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
- Seeded admin (local only): `admin@stpatrickshk.com` / `changeme` (override via `ADMIN_EMAIL` / `ADMIN_PASSWORD`)

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

- `APP_ENV` — `development` (default) allows local placeholders; set `production` / `staging` to enforce strong secrets
- `DATABASE_URL` — async Postgres URL (`@db` in Compose, `@localhost` for host runs)
- `JWT_SECRET` — signing key for access tokens
- `CORS_ORIGINS` — comma-separated
- `ADMIN_EMAIL` / `ADMIN_PASSWORD` / `ADMIN_FULL_NAME`

Frontend (`web/.env.example`):

- `VITE_API_BASE_URL` — default `http://localhost:8000`

### Rotate on deploy

Before any non-local deploy:

1. Set `APP_ENV=production` (API will refuse weak defaults).
2. Generate a fresh `JWT_SECRET` (≥32 chars), e.g. `openssl rand -hex 32`.
3. Set a unique strong `ADMIN_PASSWORD` (not `changeme`).
4. Keep values only in the host secret store / `.env` — never commit them.
5. Rotating `JWT_SECRET` invalidates all outstanding JWTs; rotating the admin password does not rewrite an already-seeded user hash — update the DB user or re-seed deliberately.

## CI

On push/PR to `main`:

- API: install deps, import `app.main`, build Docker image
- Web: lint + build when `web/package.json` exists
- Compose: `docker compose config` validation

## Ops notes

- Healthchecks: Postgres `pg_isready`; API `GET /health`
- Do not commit `.env` (gitignored)
- See [`api/API_CONTRACT.md`](api/API_CONTRACT.md) § Security / deploy hygiene
