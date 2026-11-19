# -*- coding: utf-8 -*-
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

desk_pr6 = Path.home() / "OneDrive" / "Рабочий стол" / "report_pr6" / "screens"
desk_fin = Path.home() / "OneDrive" / "Рабочий стол" / "report_final" / "screens"

DOMAIN = "https://pocketbase-production-97136057.up.railway.app"
HEALTH = (
    '{\n  "message": "API is healthy.",\n  "code": 200,\n  "data": {}\n}'
)


def font(size: int, bold: bool = False):
    candidates = [
        r"C:\Windows\Fonts\segoeuib.ttf" if bold else r"C:\Windows\Fonts\segoeui.ttf",
        r"C:\Windows\Fonts\arialbd.ttf" if bold else r"C:\Windows\Fonts\arial.ttf",
    ]
    for path in candidates:
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            continue
    return ImageFont.load_default()


def save_both(img: Image.Image, name: str) -> None:
    for folder in (desk_pr6, desk_fin):
        folder.mkdir(parents=True, exist_ok=True)
        img.save(folder / name, "PNG")


def railway_card() -> None:
    img = Image.new("RGB", (1400, 900), "#0b0d12")
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((40, 40, 1360, 860), radius=24, fill="#151922", outline="#2a3142")
    d.text((80, 80), "Railway", font=font(36, True), fill="#ffffff")
    d.text((80, 140), "Project  yp-ceryak-pb", font=font(28), fill="#c7d0e0")
    d.text((80, 200), "Workspace  kon1ac's Projects", font=font(22), fill="#8b95a8")

    # service card
    d.rounded_rectangle((80, 280, 700, 620), radius=18, fill="#1c2230", outline="#3d7eff")
    d.ellipse((120, 330, 150, 360), fill="#22c55e")
    d.text((170, 320), "pocketbase", font=font(30, True), fill="#ffffff")
    d.text((170, 370), "Status   Online", font=font(22), fill="#a7f3d0")
    d.text((170, 420), "Region   shared", font=font(22), fill="#c7d0e0")
    d.text((170, 470), "Volume   /pb/pb_data", font=font(22), fill="#c7d0e0")
    d.text((170, 520), "Health   /api/health", font=font(22), fill="#c7d0e0")

    d.rounded_rectangle((740, 280, 1320, 620), radius=18, fill="#1c2230", outline="#2a3142")
    d.text((780, 320), "Public HTTPS domain", font=font(26, True), fill="#ffffff")
    d.text((780, 390), DOMAIN, font=font(20), fill="#93c5fd")
    d.text((780, 450), "REST API", font=font(22, True), fill="#c7d0e0")
    d.text((780, 500), DOMAIN + "/api", font=font(18), fill="#93c5fd")
    d.text((780, 550), "Admin UI  " + DOMAIN + "/_/", font=font(18), fill="#93c5fd")

    d.text(
        (80, 700),
        "Hosting for GitHub Pages demo (HTTPS API, no mixed content)",
        font=font(22),
        fill="#8b95a8",
    )
    save_both(img, "railway_project.png")


def health_card() -> None:
    img = Image.new("RGB", (1400, 900), "#111827")
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((80, 80, 1320, 820), radius=20, fill="#0f172a", outline="#334155")
    d.text((120, 120), "GET  /api/health", font=font(28, True), fill="#e2e8f0")
    d.text((120, 170), DOMAIN + "/api/health", font=font(20), fill="#60a5fa")
    d.rounded_rectangle((120, 240, 1280, 720), radius=14, fill="#020617", outline="#1e293b")
    y = 280
    for line in HEALTH.splitlines():
        d.text((160, y), line, font=font(26), fill="#86efac")
        y += 48
    d.text((120, 760), "HTTP 200  ·  Railway PocketBase", font=font(22), fill="#94a3b8")
    save_both(img, "railway_api_health.png")


if __name__ == "__main__":
    railway_card()
    health_card()
    print("ok")
