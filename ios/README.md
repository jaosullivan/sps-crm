# SPS CRM iOS companion

SwiftUI app for [St. Patrick’s Society HK](https://www.stpatrickshk.com/) CRM. Same FastAPI backend as `web/`. Ticket: **KAN-7**.

This folder is a complete Xcode project. It was authored on Linux (no Xcode here); open it on a Mac to build and run.

## What it covers

| Area | Behaviour |
|------|-----------|
| Auth | `POST /api/auth/login` → JWT in Keychain. Logout deletes the Keychain items. Cold launch restores via `GET /api/auth/me`. |
| Home | `GET /api/dashboard/stats` — member/deal/sponsor/company counts, deals by stage, pipeline / won HKD. |
| Members | List + search (`?q=`), detail, create, edit. Status `active` \| `lapsed` \| `complimentary`. |
| Deals | List + search, **filter `?stage=`**, detail, create, edit, stage chips (`lead` → `contacted` → `proposal` → `won` \| `lost`). |
| Companies | Read-only picker on deal forms (`GET /api/companies`). No sponsor/company CRUD. |
| API URL | UserDefaults + iOS Settings bundle. Default `http://localhost:8000`. |

Contract: [`../api/API_CONTRACT.md`](../api/API_CONTRACT.md). The app does not invent extra endpoints.

## Prerequisites (Mac)

- Xcode 15+ (iOS 17 SDK)
- Docker Desktop (for the API)
- iPhone Simulator (any iOS 17+ device)

## Run against local Compose

### 1. Start the API

From the **repo root**:

```bash
cp .env.example .env          # first time only
docker compose up --build -d
curl -fsS http://localhost:8000/health
```

Seeded admin (dev only): `admin@stpatrickshk.com` / `changeme`.

### 2. Open the project

```bash
open ios/SPSCRM.xcodeproj
```

Or in Xcode: **File → Open…** → select `ios/SPSCRM.xcodeproj`.

The checked-in `project.pbxproj` already lists every source file. If you add files later:

```bash
# optional — only if you use XcodeGen
brew install xcodegen
cd ios && xcodegen generate
```

or regenerate the pbxproj from the tree:

```bash
python3 ios/scripts/generate_xcodeproj.py
```

### 3. Simulator

1. Scheme **SPSCRM**, destination **iPhone 16** (or any iOS 17+ Simulator).
2. Press **Run** (⌘R).
3. Sign in with `admin@stpatrickshk.com` / `changeme`.
4. API base URL should stay `http://localhost:8000` (Simulator shares the Mac network stack, so `localhost` is the Compose API).

### 4. Unit tests (optional)

In Xcode: **Product → Test** (⌘U), or:

```bash
cd ios
xcodebuild -scheme SPSCRM -destination 'platform=iOS Simulator,name=iPhone 16' test
```

## Physical device (LAN)

Simulator → `localhost` works. A phone does **not** see the Mac’s `localhost`.

1. On the Mac: `ipconfig getifaddr en0` (or System Settings → Wi‑Fi → Details).
2. Confirm the API is reachable: `curl http://<LAN-IP>:8000/health` from another machine on the same Wi‑Fi.
3. In the app: **More → API server**, set `http://<LAN-IP>:8000`.
4. Compose must publish `8000` on `0.0.0.0` (local `docker-compose.yml` does). macOS firewall must allow Docker.

`Info.plist` sets `NSAllowsLocalNetworking` plus an HTTP exception for `localhost` / `127.0.0.1`. That covers Simulator and RFC1918 LAN HTTP. If you point the app at a remote HTTP (non-TLS) host, add an ATS exception domain or use HTTPS.

You can also change the URL in **iOS Settings → SPS CRM → Base URL** (`Settings.bundle`, same UserDefaults key).

## Layout

```
ios/
  README.md
  project.yml                 # XcodeGen (optional regenerate)
  scripts/generate_xcodeproj.py
  scripts/verify_api_contract.py
  SPSCRM.xcodeproj/           # open this
  SPSCRM/                     # SwiftUI app (MVVM)
    SPSCRMApp.swift
    Theme/                    # #025C23 / #F58426 / #81AD8E / #FFFDF8
    Models/
    Services/                 # API client, Keychain, UserDefaults
    ViewModels/
    Views/                    # Login, Home, Members, Deals, More
    Settings.bundle/
    Info.plist                # ATS local-network exception
  SPSCRMTests/                # JSON + URL contract tests
```

## Brand

Tokens match the web Frontend (`web/tailwind.config.js`):

| Token | Hex |
|-------|-----|
| Primary green | `#025C23` |
| Orange | `#F58426` |
| Sage | `#81AD8E` |
| Cream | `#FFFDF8` |

## Out of scope

Sponsors/companies full CRUD, App Store / TestFlight polish, offline sync.
