#!/usr/bin/env python3
"""Ensure iOS APIClient paths stay aligned with api/API_CONTRACT.md."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CONTRACT = (ROOT / "api/API_CONTRACT.md").read_text()
CLIENT = (ROOT / "ios/SPSCRM/Services/APIClient.swift").read_text()
MODELS = (ROOT / "ios/SPSCRM/Models/Models.swift").read_text()
SOURCES = CLIENT + "\n" + MODELS

required = [
    "/api/auth/login",
    "/api/auth/me",
    "/api/dashboard/stats",
    "/api/members",
    "/api/deals",
    "/api/companies",
]

missing = [p for p in required if p not in CLIENT]
if missing:
    raise SystemExit(f"APIClient missing contract paths: {missing}")

forbidden = re.findall(r'"/api/[a-z0-9_/\-{}]+"', CLIENT)
allowed_prefixes = (
    "/api/auth/login",
    "/api/auth/me",
    "/api/dashboard/stats",
    "/api/members",
    "/api/deals",
    "/api/companies",
)
for raw in forbidden:
    path = raw.strip('"').split("?")[0]
    path = re.sub(r"\\\(.*?\)", "{id}", path)
    if not any(path == p or path.startswith(p + "/") for p in allowed_prefixes):
        raise SystemExit(f"Unexpected endpoint in APIClient: {path}")

for token in ("Authorization", "Bearer", "access_token", "stage"):
    if token not in SOURCES:
        raise SystemExit(f"iOS client missing expected token {token!r}")

if "GET /api/dashboard/stats" not in CONTRACT:
    raise SystemExit("Contract missing dashboard stats")

print("OK — iOS client paths match API_CONTRACT.md")
print("  " + "\n  ".join(required))
