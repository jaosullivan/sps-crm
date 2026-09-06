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

VITE_API_BASE_URL defaults to http://localhost:8000. See .env.example.

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
