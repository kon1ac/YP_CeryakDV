"""Seed demo data into PocketBase (called from setup_pb)."""
from __future__ import annotations

import json
import urllib.error
import urllib.request
from pathlib import Path

BASE = "http://127.0.0.1:8090"


def http(method: str, path: str, body: dict | None = None, token: str | None = None):
    data = None if body is None else json.dumps(body).encode()
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = token
    req = urllib.request.Request(
        f"{BASE}{path}", data=data, headers=headers, method=method
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            raw = resp.read().decode()
            return resp.status, json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        raw = e.read().decode()
        try:
            parsed = json.loads(raw) if raw else {}
        except json.JSONDecodeError:
            parsed = {"raw": raw}
        return e.code, parsed


def create_user(token: str, email: str, password: str, username: str, full_name: str, role: str):
    # try create via records (admin)
    code, res = http(
        "POST",
        "/api/collections/users/records",
        {
            "email": email,
            "emailVisibility": True,
            "password": password,
            "passwordConfirm": password,
            "name": full_name,
            "username": username,
            "fullName": full_name,
            "role": role,
            "verified": True,
        },
        token=token,
    )
    if code < 400:
        print("user", username, res.get("id"))
        return res["id"]
    # maybe exists — find
    code2, listed = http(
        "GET",
        f"/api/collections/users/records?filter=(username='{username}')&perPage=1",
        token=token,
    )
    items = listed.get("items") or []
    if items:
        print("user exists", username, items[0]["id"])
        return items[0]["id"]
    print("user fail", username, code, res)
    raise SystemExit(f"cannot create user {username}")


def create_rec(token: str, collection: str, body: dict) -> str:
    code, res = http(
        "POST", f"/api/collections/{collection}/records", body, token=token
    )
    if code >= 400:
        # duplicate? skip
        print("rec fail", collection, code, res)
        raise SystemExit(f"seed {collection} failed")
    return res["id"]


def seed(token: str):
    # wipe non-auth collections lightly by skipping if already seeded
    code, arenas = http(
        "GET", "/api/collections/arenas/records?perPage=1", token=token
    )
    if (arenas.get("totalItems") or 0) > 0:
        print("seed already present, skip")
        return

    admin_id = create_user(
        token, "admin@hockey.local", "admin123", "admin", "Администратор", "admin"
    )
    sponsor_id = create_user(
        token,
        "sponsor@hockey.local",
        "sponsor123",
        "sponsor",
        "Спонсор Медведей",
        "sponsor",
    )
    scout_id = create_user(
        token, "scout@hockey.local", "scout123", "scout", "Скаут лиги", "scout"
    )

    a1 = create_rec(
        token, "arenas", {"name": "Ледовый дворец", "city": "Москва", "capacity": 12000}
    )
    a2 = create_rec(
        token, "arenas", {"name": "Арена Север", "city": "СПб", "capacity": 8000}
    )
    ach1 = create_rec(
        token,
        "achievements",
        {"name": "Кубок Гагарина", "description": "Чемпион", "year": 2024},
    )
    ach2 = create_rec(
        token,
        "achievements",
        {"name": "Новичок года", "description": "Лучший дебют", "year": 2023},
    )
    t1 = create_rec(
        token,
        "teams",
        {
            "name": "Медведи",
            "city": "Москва",
            "foundedYear": 1998,
            "arena": a1,
            "sponsor": sponsor_id,
        },
    )
    t2 = create_rec(
        token,
        "teams",
        {
            "name": "Бурые Медведи",
            "city": "СПб",
            "foundedYear": 2005,
            "arena": a2,
            "sponsor": sponsor_id,
        },
    )

    players = [
        ("Александр Костров", "Нападающий", 3000, t1, 56, "in_roster", [ach1]),
        ("Алексей Платонов", "Нападающий", 4500, t2, 87, "in_roster", [ach2]),
        ("Алексей Смирнов", "Защитник", 2800, t1, 47, "injured", []),
        ("Валерий Сотников", "Нападающий", 5200, t2, 19, "in_roster", [ach1, ach2]),
        ("Игорь Волков", "Вратарь", 6100, t1, 1, "free_agent", []),
    ]
    player_ids = []
    for name, cat, price, team, jersey, status, achs in players:
        pid = create_rec(
            token,
            "players",
            {
                "name": name,
                "description": "",
                "category": cat,
                "price": price,
                "team": team,
                "jerseyNumber": jersey,
                "status": status,
                "notes": "",
            },
        )
        player_ids.append(pid)
        for ach in achs:
            create_rec(
                token,
                "player_achievements",
                {"player": pid, "achievement": ach},
            )
        if jersey in (56, 87):
            create_rec(
                token,
                "contracts",
                {
                    "player": pid,
                    "number": 1000 + jersey,
                    "email": f"{jersey}@agent.local",
                    "salary": price,
                    "signedAt": "2024-01-01",
                    "expiresAt": "2026-12-31",
                },
            )

    create_rec(
        token,
        "transfer_offers",
        {
            "player": player_ids[0],
            "team": t1,
            "sponsor": sponsor_id,
            "salary": 3500,
            "message": "Хотим усилить первое звено",
            "status": "pending",
        },
    )
    create_rec(
        token,
        "scout_reports",
        {
            "player": player_ids[0],
            "scout": scout_id,
            "rating": 8,
            "verdict": "recommend",
            "summary": "Сильный нападающий, готов к топ-клубу",
        },
    )
    create_rec(
        token,
        "scout_reports",
        {
            "player": player_ids[3],
            "scout": scout_id,
            "rating": 7,
            "verdict": "watch",
            "summary": "Следить в следующем окне",
        },
    )
    create_rec(
        token,
        "shortlist_entries",
        {
            "scout": scout_id,
            "player": player_ids[0],
            "note": "Приоритет на трансферное окно",
        },
    )
    print("seeded users", admin_id, sponsor_id, scout_id)
