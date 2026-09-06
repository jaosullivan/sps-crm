# SPS CRM Web

Frontend for St. Patricks Society Hong Kong CRM (Vite + React + TypeScript + Tailwind).

## Setup

```bash
npm install
cp .env.example .env   # optional
npm run dev
```

App runs at http://localhost:5173

## Environment

- **Local Vite:** `VITE_API_BASE_URL` defaults to `http://localhost:8000` when unset (see `.env.example`).
- **Production / Docker same-origin:** set `VITE_API_BASE_URL` to empty so API calls use relative `/api/...` (nginx proxies to the API).

## Docker (production image)

Build from the **repo root** (context = monorepo root):

```bash
docker build -f web/Dockerfile -t sps-crm/web:latest .
```

The image is multi-stage: Node 22 builds the SPA with empty `VITE_API_BASE_URL` by default, then nginx:1.27 serves `dist` and proxies `/api/` (and `/health`) to `http://api:8000`. K8s may override `default.conf` via ConfigMap; the image still ships `web/nginx.default.conf` for local `docker run`.

## Default login

- Email: admin@stpatrickshk.com
- Password: changeme

(Seeded by the API.)

## API

Expects the SPS CRM API on port 8000 (see api/API_CONTRACT.md). CORS allows http://localhost:5173.

## Scripts

- `npm run dev` - Vite dev server
- `npm run build` - Typecheck + production build
- `npm run preview` - Preview production build
- `npm run lint` - Eslint
