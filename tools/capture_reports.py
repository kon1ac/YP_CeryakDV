"""Capture screenshots for PR6 and final project reports via Playwright."""
from __future__ import annotations

import asyncio
import json
import time
import urllib.request
from pathlib import Path

from playwright.async_api import Page, async_playwright

ROOT = Path(__file__).resolve().parents[1]
PR6 = ROOT / "report_pr6" / "screens"
FINAL = ROOT / "report_final" / "screens"
APP = "http://127.0.0.1:5555"
PB = "http://127.0.0.1:8090"


def pb_login(identity: str, password: str) -> str:
    data = json.dumps({"identity": identity, "password": password}).encode()
    req = urllib.request.Request(
        f"{PB}/api/collections/users/auth-with-password",
        data=data,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=20) as resp:
        payload = json.loads(resp.read().decode())
    return payload["token"]


async def wait_flutter(page: Page, ms: int = 2500) -> None:
    await page.wait_for_timeout(ms)


async def inject_session(page: Page, identity: str, password: str) -> None:
    token = pb_login(identity, password)
    started = int(time.time() * 1000)
    # shared_preferences web stores JSON-encoded values under flutter.<key>
    script = f"""
    () => {{
      localStorage.setItem('flutter.auth_access_token', {json.dumps(json.dumps(token))});
      localStorage.setItem('flutter.auth_refresh_token', {json.dumps(json.dumps(token))});
      localStorage.setItem('flutter.auth_session_started_ms', {json.dumps(json.dumps(started))});
    }}
    """
    await page.goto(f"{APP}/login", wait_until="domcontentloaded")
    await page.evaluate(script)
    await page.goto(f"{APP}/players", wait_until="domcontentloaded")
    await wait_flutter(page, 4000)


async def clear_session(page: Page) -> None:
    await page.goto(f"{APP}/login", wait_until="domcontentloaded")
    await page.evaluate("() => { localStorage.clear(); sessionStorage.clear(); }")
    await wait_flutter(page, 800)


async def shot(page: Page, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    await page.screenshot(path=str(path), full_page=False)
    print("saved", path.relative_to(ROOT))


async def set_width(page: Page, width: int, height: int = 900) -> None:
    await page.set_viewport_size({"width": width, "height": height})
    await wait_flutter(page, 1000)


async def goto_path(page: Page, path: str) -> None:
    await page.goto(f"{APP}{path}", wait_until="domcontentloaded")
    await wait_flutter(page, 3200)


async def capture_pr6(page: Page) -> None:
    # login form screens
    await clear_session(page)
    for width in (360, 1280):
        await set_width(page, width, 740 if width < 800 else 900)
        await goto_path(page, "/login")
        await shot(page, PR6 / f"login_{width}.png")

    await inject_session(page, "admin@hockey.local", "admin123")
    screens = [
        ("/players", "players"),
        ("/teams", "teams"),
        ("/arenas", "arenas"),
        ("/achievements", "achievements"),
        ("/dashboard", "dashboard"),
        ("/players/new", "player_form"),
    ]
    for width in (360, 768, 1280, 1920):
        await set_width(page, width, 900 if width >= 768 else 740)
        for path, name in screens:
            await goto_path(page, path)
            await shot(page, PR6 / f"{name}_{width}.png")

    # deep-link SPA (direct URL)
    await set_width(page, 1280)
    await goto_path(page, "/teams")
    await shot(page, PR6 / "spa_deep_link_teams.png")


async def capture_final(page: Page) -> None:
    await page.set_viewport_size({"width": 1400, "height": 900})
    await page.goto(f"{PB}/_/", wait_until="domcontentloaded")
    await page.wait_for_timeout(2500)
    await shot(page, FINAL / "pb_admin_login.png")

    inputs = page.locator("input")
    if await inputs.count() >= 2:
        await inputs.nth(0).fill("pb-admin@hockey.local")
        await inputs.nth(1).fill("AdminPass123!")
        submit = page.locator('button[type="submit"]')
        if await submit.count():
            await submit.first.click()
        else:
            await page.keyboard.press("Enter")
        await page.wait_for_timeout(3500)
        await shot(page, FINAL / "pb_admin_home.png")
        await page.goto(f"{PB}/_/#/collections", wait_until="domcontentloaded")
        await page.wait_for_timeout(2500)
        await shot(page, FINAL / "pb_collections.png")
        await page.goto(
            f"{PB}/_/#/collections?collection=players&filter=&sort=-created",
            wait_until="domcontentloaded",
        )
        await page.wait_for_timeout(2500)
        await shot(page, FINAL / "pb_players_records.png")

    await set_width(page, 1280)
    await inject_session(page, "admin@hockey.local", "admin123")
    for path, name in [
        ("/dashboard", "app_dashboard"),
        ("/players", "app_players"),
        ("/offers", "app_offers"),
        ("/users", "app_users"),
        (
            "/players?category=%D0%9D%D0%B0%D0%BF%D0%B0%D0%B4%D0%B0%D1%8E%D1%89%D0%B8%D0%B9&sort=price%2Cdesc",
            "app_players_url_filters",
        ),
        ("/contracts", "app_contracts"),
    ]:
        await goto_path(page, path)
        await shot(page, FINAL / f"{name}.png")

    await clear_session(page)
    await inject_session(page, "sponsor@hockey.local", "sponsor123")
    await goto_path(page, "/dashboard")
    await shot(page, FINAL / "role_sponsor_dashboard.png")
    await goto_path(page, "/offers")
    await shot(page, FINAL / "role_sponsor_offers.png")
    await goto_path(page, "/users")
    await shot(page, FINAL / "role_sponsor_users_forbidden.png")

    await clear_session(page)
    await inject_session(page, "scout@hockey.local", "scout123")
    await goto_path(page, "/scout-reports")
    await shot(page, FINAL / "role_scout_reports.png")
    await goto_path(page, "/shortlist")
    await shot(page, FINAL / "role_scout_shortlist.png")
    await goto_path(page, "/offers")
    await shot(page, FINAL / "role_scout_offers_forbidden.png")
    await goto_path(page, "/dashboard")
    await shot(page, FINAL / "role_scout_dashboard_forbidden.png")


async def main() -> None:
    PR6.mkdir(parents=True, exist_ok=True)
    FINAL.mkdir(parents=True, exist_ok=True)
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page()
        print("=== PR6 screens ===")
        await capture_pr6(page)
        print("=== FINAL screens ===")
        await capture_final(page)
        await browser.close()
    print("done")


if __name__ == "__main__":
    asyncio.run(main())
