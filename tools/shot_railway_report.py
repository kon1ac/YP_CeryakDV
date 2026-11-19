# -*- coding: utf-8 -*-
from pathlib import Path

from playwright.sync_api import sync_playwright

desk_pr6 = Path.home() / "OneDrive" / "Рабочий стол" / "report_pr6" / "screens"
desk_fin = Path.home() / "OneDrive" / "Рабочий стол" / "report_final" / "screens"
desk_pr6.mkdir(parents=True, exist_ok=True)
desk_fin.mkdir(parents=True, exist_ok=True)

api = "https://pocketbase-production-97136057.up.railway.app"
pages = "https://kon1ac.github.io/YP_CeryakDV/"
railway = "https://railway.com/project/ad6cdcf8-b6ee-44aa-a8a2-f44a24f76d42"


def copy_both(src: Path, name: str) -> None:
    data = src.read_bytes()
    (desk_pr6 / name).write_bytes(data)
    (desk_fin / name).write_bytes(data)


def main() -> None:
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        ctx = browser.new_context(viewport={"width": 1400, "height": 900})
        page = ctx.new_page()

        page.goto(api + "/api/health", wait_until="domcontentloaded", timeout=60000)
        page.wait_for_timeout(500)
        health = desk_pr6 / "railway_api_health.png"
        page.screenshot(path=str(health), full_page=True)
        copy_both(health, "railway_api_health.png")
        print("health", health.stat().st_size)

        page.goto(api + "/_/", wait_until="networkidle", timeout=60000)
        page.wait_for_timeout(1200)
        login = desk_fin / "pb_admin_login.png"
        page.screenshot(path=str(login), full_page=True)
        print("pb login", login.stat().st_size)

        try:
            page.locator('input[type="text"], input[type="email"]').first.fill(
                "pb-admin@hockey.local"
            )
            page.locator('input[type="password"]').first.fill("AdminPass123!")
            page.locator('button[type="submit"]').first.click()
            page.wait_for_timeout(2500)
            home = desk_fin / "pb_admin_home.png"
            page.screenshot(path=str(home), full_page=True)
            print("pb home", home.stat().st_size)
            try:
                page.get_by_text("Collections", exact=False).first.click(timeout=4000)
                page.wait_for_timeout(1500)
                cols = desk_fin / "pb_collections.png"
                page.screenshot(path=str(cols), full_page=True)
                print("pb collections", cols.stat().st_size)
            except Exception as exc:
                print("collections skip", exc)
        except Exception as exc:
            print("pb login skip", exc)

        page.goto(pages + "login", wait_until="networkidle", timeout=90000)
        page.wait_for_timeout(4500)
        pl = desk_pr6 / "pages_login.png"
        page.screenshot(path=str(pl), full_page=True)
        copy_both(pl, "pages_login.png")
        print("pages login", pl.stat().st_size)

        page.goto(railway, wait_until="domcontentloaded", timeout=60000)
        page.wait_for_timeout(3500)
        rp = desk_pr6 / "railway_project.png"
        page.screenshot(path=str(rp), full_page=True)
        copy_both(rp, "railway_project.png")
        print("railway", rp.stat().st_size, page.url)

        browser.close()


if __name__ == "__main__":
    main()
