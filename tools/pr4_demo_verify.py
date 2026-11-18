"""Проверка сценариев показа ПР4 (блоки A/B/C) против mock API."""
from __future__ import annotations

import json
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from typing import Any

BASE = "http://127.0.0.1:8080/api"
PASS = 0
FAIL = 0


def req(
    method: str,
    path: str,
    *,
    token: str | None = None,
    body: dict | None = None,
    query: str | dict = "",
) -> tuple[int, Any]:
    url = f"{BASE}{path}"
    if query:
        if isinstance(query, dict):
            qs = urllib.parse.urlencode(query, doseq=True)
        else:
            qs = query.lstrip("?&")
        url += ("&" if "?" in url else "?") + qs
    data = None if body is None else json.dumps(body).encode()
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    request = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(request, timeout=20) as resp:
            raw = resp.read().decode()
            return resp.status, json.loads(raw) if raw else None
    except urllib.error.HTTPError as e:
        raw = e.read().decode()
        try:
            parsed = json.loads(raw) if raw else None
        except json.JSONDecodeError:
            parsed = raw
        return e.code, parsed


def check(name: str, cond: bool, detail: str = ""):
    global PASS, FAIL
    if cond:
        PASS += 1
        print(f"  OK  {name}" + (f" — {detail}" if detail else ""))
    else:
        FAIL += 1
        print(f" FAIL {name}" + (f" — {detail}" if detail else ""))


def login(user: str, password: str) -> str:
    code, data = req("POST", "/auth/login", body={"username": user, "password": password})
    assert code == 200 and isinstance(data, dict), data
    return data["accessToken"]


def main():
    print("=== PREP ===")
    code, health = req("GET", "/__health")
    check("A0 health", code == 200 and health.get("status") == "ok", str(health))
    token = login("admin", "admin123")
    check("prep login admin", bool(token))

    print("\n=== BLOCK A ===")
    code, page = req("GET", "/players", token=token, query="page=1&size=5")
    check("A1 list from server", code == 200 and isinstance(page, dict) and "items" in page,
          f"items={len(page.get('items', []))} total={page.get('total')}")
    code, empty = req("GET", "/players", token=token, query="search=zzz_empty_no_match_999&page=1&size=10")
    check("A5 empty result", code == 200 and empty.get("total") == 0, f"total={empty.get('total')}")
    t0 = time.time()
    code, _ = req("GET", "/players", token=token, query="page=1&size=2&__delay=800")
    dt = time.time() - t0
    check("A3 delay __delay", code == 200 and dt >= 0.7, f"{dt:.2f}s")
    code, fail = req("GET", "/players", token=token, query="page=1&size=2&__fail=500")
    check("A6 __fail=500", code == 500, f"status={code} body={fail}")

    print("\n=== BLOCK B ===")
    # occupied jersey from list
    code, full = req("GET", "/players", token=token, query="page=1&size=50")
    jerseys = [p.get("jerseyNumber") for p in full["items"] if p.get("jerseyNumber")]
    taken = jerseys[0] if jerseys else 56
    check("B0 have jersey for 422", bool(taken), f"jersey={taken}")

    # create unique player
    unique_jersey = 91
    while unique_jersey in jerseys:
        unique_jersey = (unique_jersey % 99) + 1
    create_body = {
        "name": "ПР4 Демо Игрок",
        "category": "Нападающий",
        "price": 1000,
        "jerseyNumber": unique_jersey,
        "status": "in_roster",
        "notes": "demo pr4",
        "teamId": full["items"][0].get("teamId") or full["items"][0].get("team", {}).get("id"),
        "achievementIds": [],
    }
    # teamId may be nested
    if not create_body["teamId"]:
        code, teams = req("GET", "/teams", token=token, query="page=1&size=1")
        create_body["teamId"] = teams["items"][0]["id"]

    code, created = req("POST", "/players", token=token, body=create_body)
    check("B1 create", code in (200, 201) and isinstance(created, dict) and created.get("id"),
          f"status={code} id={created.get('id') if isinstance(created, dict) else created}")
    pid = created["id"] if isinstance(created, dict) else None

    if pid:
        code, one = req("GET", f"/players/{pid}", token=token)
        check("B2 read", code == 200 and one.get("id") == pid)
        code, updated = req("PUT", f"/players/{pid}", token=token, body={**create_body, "notes": "updated"})
        check("B2 update", code == 200 and updated.get("notes") == "updated", f"notes={updated.get('notes')}")

        code, _ = req("DELETE", f"/players/{pid}", token=token)
        check("B3 soft delete", code in (200, 204), f"status={code}")
        code, deleted_list = req(
            "GET",
            "/players",
            token=token,
            query={"includeDeleted": "true", "search": "ПР4 Демо"},
        )
        soft = next((p for p in deleted_list.get("items", []) if p.get("id") == pid), None)
        check("B3 visible when includeDeleted", soft is not None and soft.get("deletedAt"),
              f"deletedAt={soft.get('deletedAt') if soft else None}")

        code, restored = req("POST", f"/players/{pid}/restore", token=token)
        if code >= 400:
            # some APIs use PUT restore
            code, restored = req("PUT", f"/players/{pid}/restore", token=token)
        check("B4 restore", code in (200, 204) or (
            req("GET", f"/players/{pid}", token=token)[0] == 200
        ), f"status={code}")

        # 422 duplicate jersey
        code, err422 = req(
            "POST",
            "/players",
            token=token,
            body={**create_body, "name": "Дубль номера", "jerseyNumber": taken},
        )
        check(
            "B8 validation 422 jersey",
            code == 422 and isinstance(err422, dict) and (
                "jerseyNumber" in (err422.get("errors") or {}) or "номер" in str(err422).lower()
            ),
            f"status={code} body={err422}",
        )

        # hard delete demo player
        code, _ = req("DELETE", f"/players/{pid}", token=token, query="hard=true")
        check("B5 hard delete", code in (200, 204), f"status={code}")

    # bulk delete: create two temp then bulk
    ids = []
    for i in range(2):
        jn = unique_jersey + 1 + i
        while jn in jerseys or jn == unique_jersey:
            jn = (jn % 99) + 1
        code, row = req(
            "POST",
            "/players",
            token=token,
            body={**create_body, "name": f"Bulk {i}", "jerseyNumber": jn},
        )
        if code in (200, 201):
            ids.append(row["id"])
    if ids:
        code, bulk = req("POST", "/players/bulk-delete", token=token, body={"ids": ids})
        check("B6 bulk delete", code == 200, f"status={code} body={bulk}")
        # cleanup hard
        for i in ids:
            req("DELETE", f"/players/{i}", token=token, query="hard=true")

    # 409: try hard-delete arena in use
    code, arenas = req("GET", "/arenas", token=token, query="page=1&size=5")
    arena_id = arenas["items"][0]["id"] if arenas.get("items") else None
    if arena_id:
        code, err409 = req("DELETE", f"/arenas/{arena_id}", token=token, query="hard=true")
        # soft may work; hard with links -> 409
        if code != 409:
            code, err409 = req("DELETE", f"/arenas/{arena_id}", token=token)
        check("B9 conflict 409", code == 409, f"status={code} body={err409}")

    print("\n=== BLOCK C ===")
    code, p1 = req("GET", "/players", token=token, query="page=1&size=3")
    code, p2 = req("GET", "/players", token=token, query="page=2&size=3")
    check(
        "C1 server pagination",
        code == 200 and p1.get("page") == 1 and p2.get("page") == 2 and p1.get("items") != p2.get("items"),
        f"p1={[i.get('name') for i in p1.get('items',[])]} p2={[i.get('name') for i in p2.get('items',[])]}",
    )
    code, sorted_asc = req("GET", "/players", token=token, query="page=1&size=5&sort=name,asc")
    code, search = req(
        "GET",
        "/players",
        token=token,
        query={"page": "1", "size": "5", "search": "Александр"},
    )
    check("C2 search on server", code == 200 and search.get("total", 0) >= 1, f"total={search.get('total')}")
    check("C2 sort param accepted", sorted_asc.get("items") is not None, f"count={len(sorted_asc.get('items',[]))}")

    print(f"\n=== RESULT: {PASS} passed, {FAIL} failed ===")
    return 0 if FAIL == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
