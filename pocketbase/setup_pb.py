"""Initialize PocketBase 0.34+: superuser, collections (flat fields), seed."""
from __future__ import annotations

import json
import subprocess
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PB = ROOT / "pocketbase.exe"
DIR = ROOT / "pb_data"
BASE = "http://127.0.0.1:8090"
ADMIN_EMAIL = "pb-admin@hockey.local"
ADMIN_PASS = "AdminPass123!"


def http(method: str, path: str, body: dict | None = None, token: str | None = None):
    data = None if body is None else json.dumps(body).encode()
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = token
    req = urllib.request.Request(
        f"{BASE}{path}", data=data, headers=headers, method=method
    )
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            raw = resp.read().decode()
            return resp.status, json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        raw = e.read().decode()
        try:
            parsed = json.loads(raw) if raw else {}
        except json.JSONDecodeError:
            parsed = {"raw": raw}
        return e.code, parsed


def wait_ready(seconds: float = 40):
    deadline = time.time() + seconds
    while time.time() < deadline:
        try:
            urllib.request.urlopen(f"{BASE}/api/health", timeout=2)
            return
        except Exception:
            time.sleep(0.4)
    raise SystemExit("PocketBase did not start")


def text(name: str, required: bool = False, max_len: int = 255, min_len: int = 0):
    return {
        "name": name,
        "type": "text",
        "required": required,
        "presentable": False,
        "system": False,
        "min": min_len,
        "max": max_len,
        "pattern": "",
    }


def number(name: str, required: bool = False, min_v=None, max_v=None, only_int=False):
    return {
        "name": name,
        "type": "number",
        "required": required,
        "presentable": False,
        "system": False,
        "min": min_v,
        "max": max_v,
        "onlyInt": only_int,
    }


def date(name: str, required: bool = False):
    return {
        "name": name,
        "type": "date",
        "required": required,
        "presentable": False,
        "system": False,
        "min": "",
        "max": "",
    }


def select(name: str, values: list[str], required: bool = False):
    return {
        "name": name,
        "type": "select",
        "required": required,
        "presentable": False,
        "system": False,
        "maxSelect": 1,
        "values": values,
    }


def relation(name: str, collection_id: str, required: bool = False, max_select: int = 1):
    return {
        "name": name,
        "type": "relation",
        "required": required,
        "presentable": False,
        "system": False,
        "collectionId": collection_id,
        "cascadeDelete": False,
        "maxSelect": max_select,
        "minSelect": 0,
        "displayFields": [],
    }


def ensure_collection(token: str, payload: dict):
    code, existing = http("GET", f"/api/collections/{payload['name']}", token=token)
    if code == 200:
        body = {**payload, "id": existing["id"]}
        # keep system fields from existing
        sys_fields = [f for f in existing.get("fields", []) if f.get("system")]
        body["fields"] = sys_fields + payload["fields"]
        code2, updated = http(
            "PATCH", f"/api/collections/{existing['id']}", body=body, token=token
        )
        print("update", payload["name"], code2)
        if code2 >= 400:
            print(json.dumps(updated, ensure_ascii=False)[:400])
            raise SystemExit(f"update failed {payload['name']}")
        return updated
    code2, created = http("POST", "/api/collections", body=payload, token=token)
    print("create", payload["name"], code2)
    if code2 >= 400:
        print(json.dumps(created, ensure_ascii=False)[:500])
        raise SystemExit(f"create failed {payload['name']}")
    return created


def main():
    subprocess.run(
        [str(PB), "superuser", "upsert", ADMIN_EMAIL, ADMIN_PASS, "--dir", str(DIR)],
        check=False,
        cwd=str(ROOT),
    )
    proc = subprocess.Popen(
        [str(PB), "serve", "--dir", str(DIR), "--http", "127.0.0.1:8090"],
        cwd=str(ROOT),
    )
    try:
        wait_ready()
        code, auth = http(
            "POST",
            "/api/collections/_superusers/auth-with-password",
            {"identity": ADMIN_EMAIL, "password": ADMIN_PASS},
        )
        if code >= 400:
            print(auth)
            raise SystemExit("admin auth failed")
        token = auth["token"]

        _, users = http("GET", "/api/collections/users", token=token)
        users_id = users["id"]
        field_names = {f["name"] for f in users.get("fields", [])}
        extras = []
        if "username" not in field_names:
            extras.append(text("username", True, 60, 3))
        if "fullName" not in field_names:
            extras.append(text("fullName", True, 120, 1))
        if "role" not in field_names:
            extras.append(select("role", ["admin", "sponsor", "scout"], True))
        if "deletedAt" not in field_names:
            extras.append(date("deletedAt"))
        if extras:
            body = {
                "fields": users.get("fields", []) + extras,
                "listRule": '@request.auth.id != "" && @request.auth.role = "admin"',
                "viewRule": '@request.auth.id != "" && (@request.auth.role = "admin" || id = @request.auth.id)',
                "createRule": "",
                "updateRule": '@request.auth.id != "" && @request.auth.role = "admin"',
                "deleteRule": '@request.auth.id != "" && @request.auth.role = "admin"',
            }
            code_u, res_u = http(
                "PATCH", f"/api/collections/{users_id}", body=body, token=token
            )
            print("users patch", code_u, res_u.get("message", ""))
            if code_u >= 400:
                print(json.dumps(res_u, ensure_ascii=False)[:500])

        _, users = http("GET", "/api/collections/users", token=token)
        users_id = users["id"]

        auth_list = '@request.auth.id != ""'
        admin_w = '@request.auth.id != "" && @request.auth.role = "admin"'
        sponsor_w = '@request.auth.id != "" && (@request.auth.role = "admin" || @request.auth.role = "sponsor")'
        scout_w = '@request.auth.id != "" && (@request.auth.role = "admin" || @request.auth.role = "scout")'
        offer_r = sponsor_w
        scout_r = scout_w

        arenas = ensure_collection(
            token,
            {
                "name": "arenas",
                "type": "base",
                "fields": [
                    text("name", True, 120, 1),
                    text("city", True, 80, 1),
                    number("capacity", True, 1, None, True),
                    date("deletedAt"),
                ],
                "listRule": auth_list,
                "viewRule": auth_list,
                "createRule": admin_w,
                "updateRule": admin_w,
                "deleteRule": admin_w,
            },
        )
        achievements = ensure_collection(
            token,
            {
                "name": "achievements",
                "type": "base",
                "fields": [
                    text("name", True, 120, 1),
                    text("description", False, 2000),
                    number("year", False, 1900, 2100, True),
                    date("deletedAt"),
                ],
                "listRule": auth_list,
                "viewRule": auth_list,
                "createRule": admin_w,
                "updateRule": admin_w,
                "deleteRule": admin_w,
            },
        )
        teams = ensure_collection(
            token,
            {
                "name": "teams",
                "type": "base",
                "fields": [
                    text("name", True, 120, 1),
                    text("city", True, 80, 1),
                    number("foundedYear", False, 1900, 2100, True),
                    relation("arena", arenas["id"], True),
                    relation("sponsor", users_id, False),
                    date("deletedAt"),
                ],
                "listRule": auth_list,
                "viewRule": auth_list,
                "createRule": sponsor_w,
                "updateRule": sponsor_w,
                "deleteRule": sponsor_w,
            },
        )
        players = ensure_collection(
            token,
            {
                "name": "players",
                "type": "base",
                "fields": [
                    text("name", True, 120, 1),
                    text("description", False, 2000),
                    text("category", True, 60, 1),
                    number("price", True, 0, None, False),
                    relation("team", teams["id"], True),
                    number("jerseyNumber", False, 1, 99, True),
                    select(
                        "status",
                        ["in_roster", "injured", "suspended", "free_agent"],
                        True,
                    ),
                    text("notes", False, 2000),
                    date("deletedAt"),
                ],
                "listRule": auth_list,
                "viewRule": auth_list,
                "createRule": sponsor_w,
                "updateRule": sponsor_w,
                "deleteRule": sponsor_w,
            },
        )
        ensure_collection(
            token,
            {
                "name": "player_achievements",
                "type": "base",
                "fields": [
                    relation("player", players["id"], True),
                    relation("achievement", achievements["id"], True),
                ],
                "listRule": auth_list,
                "viewRule": auth_list,
                "createRule": sponsor_w,
                "updateRule": sponsor_w,
                "deleteRule": sponsor_w,
                "indexes": [
                    "CREATE UNIQUE INDEX `idx_player_ach` ON `player_achievements` (`player`, `achievement`)"
                ],
            },
        )
        ensure_collection(
            token,
            {
                "name": "contracts",
                "type": "base",
                "fields": [
                    relation("player", players["id"], True),
                    number("number", False, 1, None, True),
                    text("email", False, 120),
                    number("salary", False, 0, None, False),
                    date("signedAt"),
                    date("expiresAt"),
                    date("deletedAt"),
                ],
                "listRule": auth_list,
                "viewRule": auth_list,
                "createRule": sponsor_w,
                "updateRule": sponsor_w,
                "deleteRule": sponsor_w,
                "indexes": [
                    "CREATE UNIQUE INDEX `idx_contract_player` ON `contracts` (`player`)"
                ],
            },
        )
        ensure_collection(
            token,
            {
                "name": "transfer_offers",
                "type": "base",
                "fields": [
                    relation("player", players["id"], True),
                    relation("team", teams["id"], True),
                    relation("sponsor", users_id, True),
                    number("salary", True, 0, None, False),
                    text("message", False, 2000),
                    select("status", ["pending", "accepted", "rejected"], True),
                    date("deletedAt"),
                ],
                "listRule": offer_r,
                "viewRule": offer_r,
                "createRule": offer_r,
                "updateRule": offer_r,
                "deleteRule": offer_r,
            },
        )
        ensure_collection(
            token,
            {
                "name": "scout_reports",
                "type": "base",
                "fields": [
                    relation("player", players["id"], True),
                    relation("scout", users_id, True),
                    number("rating", True, 1, 10, True),
                    select("verdict", ["recommend", "watch", "reject"], True),
                    text("summary", True, 2000, 1),
                    date("deletedAt"),
                ],
                "listRule": scout_r,
                "viewRule": scout_r,
                "createRule": scout_r,
                "updateRule": scout_r,
                "deleteRule": scout_r,
            },
        )
        ensure_collection(
            token,
            {
                "name": "shortlist_entries",
                "type": "base",
                "fields": [
                    relation("scout", users_id, True),
                    relation("player", players["id"], True),
                    text("note", False, 2000),
                    date("deletedAt"),
                ],
                "listRule": scout_r,
                "viewRule": scout_r,
                "createRule": scout_r,
                "updateRule": scout_r,
                "deleteRule": scout_r,
            },
        )

        code, cols = http("GET", "/api/collections?perPage=100", token=token)
        (ROOT / "pb_schema.json").write_text(
            json.dumps(cols, ensure_ascii=False, indent=2), encoding="utf-8"
        )
        print("schema exported")

        from seed_pb import seed

        seed(token)
        print("SETUP COMPLETE")
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except Exception:
            proc.kill()


if __name__ == "__main__":
    main()
