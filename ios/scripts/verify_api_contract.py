#!/usr/bin/env python3
"""Hit the same endpoints the iOS app uses. Run with API up: docker compose up -d."""

from __future__ import annotations

import json
import sys
import urllib.error
import urllib.request

BASE = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:8000"
EMAIL = "admin@stpatrickshk.com"
PASSWORD = "changeme"


def req(method: str, path: str, body: dict | None = None, token: str | None = None, expected: int = 200):
    data = None if body is None else json.dumps(body).encode()
    headers = {"Accept": "application/json"}
    if data is not None:
        headers["Content-Type"] = "application/json"
    if token:
        headers["Authorization"] = f"Bearer {token}"
    r = urllib.request.Request(BASE + path, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(r, timeout=10) as resp:
            status = resp.status
            raw = resp.read()
    except urllib.error.HTTPError as e:
        status = e.code
        raw = e.read()
        if status != expected:
            raise SystemExit(f"{method} {path} -> {status}: {raw.decode()[:400]}") from e
    if status != expected:
        raise SystemExit(f"{method} {path} expected {expected}, got {status}: {raw.decode()[:400]}")
    if status == 204 or not raw:
        return None
    return json.loads(raw)


def main() -> None:
    health = req("GET", "/health")
    assert health.get("status") == "ok", health

    login = req("POST", "/api/auth/login", {"email": EMAIL, "password": PASSWORD})
    token = login["access_token"]
    assert login["token_type"] == "bearer"
    assert login["user"]["email"] == EMAIL

    me = req("GET", "/api/auth/me", token=token)
    assert me["email"] == EMAIL

    stats = req("GET", "/api/dashboard/stats", token=token)
    for key in (
        "members_total",
        "members_active",
        "sponsors_total",
        "companies_total",
        "deals_total",
        "deals_by_stage",
        "pipeline_value_hkd",
        "won_value_hkd",
    ):
        assert key in stats, stats

    members = req("GET", "/api/members", token=token)
    assert isinstance(members, list)
    searched = req("GET", "/api/members?q=Aoife", token=token)
    assert isinstance(searched, list)

    created = req(
        "POST",
        "/api/members",
        {
            "first_name": "Niamh",
            "last_name": "ContractCheck",
            "email": "niamh.contractcheck@example.com",
            "status": "complimentary",
            "phone": None,
            "company_name": None,
            "green_card_number": None,
            "joined_on": "2026-03-17",
            "notes": "ios verify",
        },
        token=token,
        expected=201,
    )
    mid = created["id"]
    got = req("GET", f"/api/members/{mid}", token=token)
    assert got["status"] == "complimentary"
    patched = req("PATCH", f"/api/members/{mid}", {"status": "active"}, token=token)
    assert patched["status"] == "active"
    req("DELETE", f"/api/members/{mid}", token=token, expected=204)

    companies = req("GET", "/api/companies", token=token)
    assert isinstance(companies, list)
    company_id = companies[0]["id"] if companies else None

    deals = req("GET", "/api/deals", token=token)
    assert isinstance(deals, list)
    staged = req("GET", "/api/deals?stage=proposal", token=token)
    assert all(d["stage"] == "proposal" for d in staged)

    deal = req(
        "POST",
        "/api/deals",
        {
            "title": "iOS contract check",
            "company_id": company_id,
            "stage": "lead",
            "value_hkd": 1000,
            "contact_name": "Test",
            "contact_email": None,
            "expected_close": None,
            "notes": None,
        },
        token=token,
        expected=201,
    )
    did = deal["id"]
    moved = req("PATCH", f"/api/deals/{did}", {"stage": "contacted"}, token=token)
    assert moved["stage"] == "contacted"
    req("DELETE", f"/api/deals/{did}", token=token, expected=204)

    print("OK — iOS-used endpoints match API_CONTRACT.md against", BASE)


if __name__ == "__main__":
    main()
