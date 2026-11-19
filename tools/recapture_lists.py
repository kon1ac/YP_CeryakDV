"""Re-capture list/dashboard screens after data settles."""
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
        return json.loads(resp.read().decode())["token"]


async def inject(page: Page, identity: str, password: str) -> None:
    token = pb_login(identity, password)
    started = int(time.time() * 1000)
    await page.goto(f"{APP}/login", wait_until="domcontentloaded")
    await page.evaluate(
        """([token, started]) => {
          localStorage.setItem('flutter.auth_access_token', JSON.stringify(token));
          localStorage.setItem('flutter.auth_refresh_token', JSON.stringify(token));
          localStorage.setItem('flutter.auth_session_started_ms', JSON.stringify(started));
        }""",
        [token, started],
    )


async def wait_settled(page: Page, timeout_ms: int = 12000) -> None:
    await page.wait_for_timeout(2000)
    deadline = time.time() + timeout_ms / 1000
    while time.time() < deadline:
        text = await page.evaluate("() => document.body.innerText || ''")
        busy = any(
            s in text
            for s in ("Ищем", "Загрузка", "CircularProgress", "…")
        )
        # Flutter canvas may not expose text; also check network quiet
        if not busy:
            await page.wait_for_timeout(1500)
            return
        await page.wait_for_timeout(500)
    await page.wait_for_timeout(2000)


async def shot(page: Page, path: Path) -> None:
    await page.screenshot(path=str(path), full_page=False)
    print("saved", path.name)


async def goto(page: Page, path: str) -> None:
    await page.goto(f"{APP}{path}", wait_until="networkidle")
    await wait_settled(page)


async def main() -> None:
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page(viewport={"width": 1280, "height": 900})
        await inject(page, "admin@hockey.local", "admin123")

        # PR6 adaptive with longer settle
        for width in (360, 768, 1280, 1920):
            await page.set_viewport_size(
                {"width": width, "height": 740 if width < 800 else 900}
            )
            for path, name in [
                ("/players", "players"),
                ("/teams", "teams"),
                ("/arenas", "arenas"),
                ("/achievements", "achievements"),
                ("/dashboard", "dashboard"),
                ("/players/new", "player_form"),
            ]:
                await goto(page, path)
                await shot(page, PR6 / f"{name}_{width}.png")

        await page.set_viewport_size({"width": 1280, "height": 900})
        await goto(page, "/teams")
        await shot(page, PR6 / "spa_deep_link_teams.png")

        # FINAL app screens
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
            await goto(page, path)
            await shot(page, FINAL / f"{name}.png")

        # sponsor / scout
        await inject(page, "sponsor@hockey.local", "sponsor123")
        await goto(page, "/dashboard")
        await shot(page, FINAL / "role_sponsor_dashboard.png")
        await goto(page, "/offers")
        await shot(page, FINAL / "role_sponsor_offers.png")
        await goto(page, "/users")
        await shot(page, FINAL / "role_sponsor_users_forbidden.png")

        await inject(page, "scout@hockey.local", "scout123")
        await goto(page, "/scout-reports")
        await shot(page, FINAL / "role_scout_reports.png")
        await goto(page, "/shortlist")
        await shot(page, FINAL / "role_scout_shortlist.png")
        await goto(page, "/offers")
        await shot(page, FINAL / "role_scout_offers_forbidden.png")
        await goto(page, "/dashboard")
        await shot(page, FINAL / "role_scout_dashboard_forbidden.png")

        await browser.close()
    print("done")


if __name__ == "__main__":
    asyncio.run(main())
