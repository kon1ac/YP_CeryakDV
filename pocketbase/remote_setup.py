"""Apply schema + seed to a remote PocketBase (Railway HTTPS)."""
from __future__ import annotations

import sys

import seed_pb
import setup_pb as s

BASE = sys.argv[1] if len(sys.argv) > 1 else "https://example.up.railway.app"
s.BASE = BASE.rstrip("/")
seed_pb.BASE = s.BASE


def run():
    s.wait_ready(90)
    code, auth = s.http(
        "POST",
        "/api/collections/_superusers/auth-with-password",
        {"identity": s.ADMIN_EMAIL, "password": s.ADMIN_PASS},
    )
    if code >= 400:
        raise SystemExit(f"superuser auth failed: {code} {auth}")
    token = auth["token"]

    code, users = s.http("GET", "/api/collections/users", token=token)
    if code >= 400:
        raise SystemExit(f"users collection: {code} {users}")
    users_id = users["id"]

    fields = users.get("fields") or []
    names = {f.get("name") for f in fields}
    body = {"fields": fields}
    changed = False
    if "role" not in names:
        body["fields"] = fields + [
            s.select("role", ["admin", "sponsor", "scout"], True)
        ]
        changed = True
        fields = body["fields"]
        names = {f.get("name") for f in fields}
    if "fullName" not in names:
        body["fields"] = fields + [s.text("fullName", False, 120)]
        changed = True
    if "username" not in names:
        body["fields"] = (body.get("fields") or fields) + [
            s.text("username", True, 60, 3)
        ]
        changed = True
    if changed:
        code, _ = s.http(
            "PATCH", f"/api/collections/{users_id}", body=body, token=token
        )
        print("users fields patch", code)

    auth_list = "@request.auth.id != ''"
    admin_w = "@request.auth.role = 'admin'"
    sponsor_w = "@request.auth.role = 'admin' || @request.auth.role = 'sponsor'"
    scout_r = "@request.auth.role = 'admin' || @request.auth.role = 'scout'"
    offer_r = "@request.auth.role = 'admin' || @request.auth.role = 'sponsor'"

    arenas = s.ensure_collection(
        token,
        {
            "name": "arenas",
            "type": "base",
            "fields": [
                s.text("name", True, 120, 1),
                s.text("city", True, 80, 1),
                s.number("capacity", True, 1, None, True),
                s.date("deletedAt"),
            ],
            "listRule": auth_list,
            "viewRule": auth_list,
            "createRule": admin_w,
            "updateRule": admin_w,
            "deleteRule": admin_w,
        },
    )
    achievements = s.ensure_collection(
        token,
        {
            "name": "achievements",
            "type": "base",
            "fields": [
                s.text("name", True, 120, 1),
                s.text("description", False, 2000),
                s.number("year", False, 1900, 2100, True),
                s.date("deletedAt"),
            ],
            "listRule": auth_list,
            "viewRule": auth_list,
            "createRule": admin_w,
            "updateRule": admin_w,
            "deleteRule": admin_w,
        },
    )
    teams = s.ensure_collection(
        token,
        {
            "name": "teams",
            "type": "base",
            "fields": [
                s.text("name", True, 120, 1),
                s.text("city", True, 80, 1),
                s.number("foundedYear", False, 1900, 2100, True),
                s.relation("arena", arenas["id"], True),
                s.relation("sponsor", users_id, False),
                s.date("deletedAt"),
            ],
            "listRule": auth_list,
            "viewRule": auth_list,
            "createRule": sponsor_w,
            "updateRule": sponsor_w,
            "deleteRule": sponsor_w,
        },
    )
    players = s.ensure_collection(
        token,
        {
            "name": "players",
            "type": "base",
            "fields": [
                s.text("name", True, 120, 1),
                s.text("description", False, 2000),
                s.text("category", True, 60, 1),
                s.number("price", True, 0, None, False),
                s.relation("team", teams["id"], True),
                s.number("jerseyNumber", False, 1, 99, True),
                s.select(
                    "status",
                    ["in_roster", "injured", "suspended", "free_agent"],
                    True,
                ),
                s.text("notes", False, 2000),
                s.date("deletedAt"),
            ],
            "listRule": auth_list,
            "viewRule": auth_list,
            "createRule": sponsor_w,
            "updateRule": sponsor_w,
            "deleteRule": sponsor_w,
        },
    )
    s.ensure_collection(
        token,
        {
            "name": "player_achievements",
            "type": "base",
            "fields": [
                s.relation("player", players["id"], True),
                s.relation("achievement", achievements["id"], True),
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
    s.ensure_collection(
        token,
        {
            "name": "contracts",
            "type": "base",
            "fields": [
                s.relation("player", players["id"], True),
                s.number("number", False, 1, None, True),
                s.text("email", False, 120),
                s.number("salary", False, 0, None, False),
                s.date("signedAt"),
                s.date("expiresAt"),
                s.date("deletedAt"),
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
    s.ensure_collection(
        token,
        {
            "name": "transfer_offers",
            "type": "base",
            "fields": [
                s.relation("player", players["id"], True),
                s.relation("team", teams["id"], True),
                s.relation("sponsor", users_id, True),
                s.number("salary", True, 0, None, False),
                s.text("message", False, 2000),
                s.select("status", ["pending", "accepted", "rejected"], True),
                s.date("deletedAt"),
            ],
            "listRule": offer_r,
            "viewRule": offer_r,
            "createRule": offer_r,
            "updateRule": offer_r,
            "deleteRule": offer_r,
        },
    )
    s.ensure_collection(
        token,
        {
            "name": "scout_reports",
            "type": "base",
            "fields": [
                s.relation("player", players["id"], True),
                s.relation("scout", users_id, True),
                s.number("rating", True, 1, 10, True),
                s.select("verdict", ["recommend", "watch", "reject"], True),
                s.text("summary", True, 2000, 1),
                s.date("deletedAt"),
            ],
            "listRule": scout_r,
            "viewRule": scout_r,
            "createRule": scout_r,
            "updateRule": scout_r,
            "deleteRule": scout_r,
        },
    )
    s.ensure_collection(
        token,
        {
            "name": "shortlist_entries",
            "type": "base",
            "fields": [
                s.relation("scout", users_id, True),
                s.relation("player", players["id"], True),
                s.text("note", False, 2000),
                s.date("deletedAt"),
            ],
            "listRule": scout_r,
            "viewRule": scout_r,
            "createRule": scout_r,
            "deleteRule": scout_r,
            "updateRule": scout_r,
        },
    )

    seed_pb.seed(token)
    print("REMOTE SETUP COMPLETE", s.BASE)


if __name__ == "__main__":
    run()
