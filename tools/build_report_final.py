# -*- coding: utf-8 -*-
"""Build final project report (PocketBase, grade 5)."""
from __future__ import annotations

from pathlib import Path

from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml.ns import qn
from docx.shared import Cm, Pt, RGBColor

ROOT = Path(__file__).resolve().parents[1]
DESK = Path.home() / "OneDrive" / "Рабочий стол" / "report_final"
SCREENS = DESK / "screens" if (DESK / "screens").exists() else ROOT / "report_final" / "screens"
OUT = (
    DESK / "Otchet_Itogovy_proekt.docx"
    if DESK.exists()
    else ROOT / "report_final" / "Otchet_Itogovy_proekt.docx"
)

API_RAILWAY = "https://pocketbase-production-97136057.up.railway.app/api"
API_HOST = "https://pocketbase-production-97136057.up.railway.app"
APP_PAGES = "https://kon1ac.github.io/YP_CeryakDV/"


def set_run_font(run, size=14, bold=False):
    run.font.name = "Times New Roman"
    run._element.rPr.rFonts.set(qn("w:eastAsia"), "Times New Roman")
    run.font.size = Pt(size)
    run.bold = bold
    run.font.color.rgb = RGBColor(0, 0, 0)


def add_p(doc, text, *, size=14, bold=False, center=False, space_after=8):
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(space_after)
    p.paragraph_format.space_before = Pt(0)
    if center:
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = p.add_run(text)
    set_run_font(run, size=size, bold=bold)
    return p


def add_h(doc, text, level=1):
    p = doc.add_heading(text, level=level)
    for run in p.runs:
        set_run_font(run, size=16 if level == 1 else 14, bold=True)
    return p


def add_img(doc, name, caption, width_cm=15.5):
    path = SCREENS / name
    if not path.exists():
        add_p(doc, f"[нет файла {name}]", bold=True)
        return
    doc.add_picture(str(path), width=Cm(width_cm))
    doc.paragraphs[-1].alignment = WD_ALIGN_PARAGRAPH.CENTER
    add_p(doc, caption, size=12, center=True, space_after=14)


def add_table(doc, headers, rows):
    table = doc.add_table(rows=1 + len(rows), cols=len(headers))
    table.style = "Table Grid"
    for i, h in enumerate(headers):
        cell = table.rows[0].cells[i]
        cell.text = h
        for p in cell.paragraphs:
            for r in p.runs:
                set_run_font(r, size=12, bold=True)
    for ri, row in enumerate(rows):
        for ci, val in enumerate(row):
            cell = table.rows[ri + 1].cells[ci]
            cell.text = str(val)
            for p in cell.paragraphs:
                for r in p.runs:
                    set_run_font(r, size=12)
    doc.add_paragraph()


def main():
    doc = Document()
    section = doc.sections[0]
    section.top_margin = Cm(2)
    section.bottom_margin = Cm(2)
    section.left_margin = Cm(2.5)
    section.right_margin = Cm(2)

    add_p(doc, "Итоговый проект", size=18, bold=True, center=True)
    add_p(
        doc,
        "«Витрина хоккейных игроков» (Молодёжка) на Flutter Web + PocketBase",
        size=15,
        bold=True,
        center=True,
        space_after=18,
    )

    add_h(doc, "1. Предметная область и цель")
    add_p(
        doc,
        "Магазин/каталог хоккейных игроков по мотивам сериала «Молодёжка». "
        "Клиент на Flutter Web, сервер — PocketBase (REST по схеме без собственного backend-кода). "
        "Цель — оценка «5»: полный CRUD, роли, soft/hard delete, URL-фильтры, сеть/ошибки, "
        "публикация и содержательная фича (дашборд + CSV + диаграммы).",
    )

    add_h(doc, "2. Серверная часть — PocketBase")
    add_p(
        doc,
        "Локально: ./pocketbase/pocketbase.exe serve — панель http://127.0.0.1:8090/_/, "
        "API http://127.0.0.1:8090/api/, SQLite в pocketbase/pb_data. "
        "Схема — pocketbase/pb_schema.json, сид — seed_pb.py / remote_setup.py.",
    )
    add_p(
        doc,
        "Для опубликованного клиента на GitHub Pages API поднят на Railway (HTTPS), "
        f"чтобы не было mixed content: {API_HOST} "
        f"(REST {API_RAILWAY}, админка {API_HOST}/_/). "
        "Проект Railway: yp-ceryak-pb, сервис pocketbase, volume /pb/pb_data.",
    )
    add_p(doc, "Учётки приложения: admin / sponsor / scout (пароли *123). "
          "Суперпользователь панели: pb-admin@hockey.local / AdminPass123!.")
    add_img(doc, "railway_project.png", "Рисунок 1 — Хостинг API на Railway")
    add_img(doc, "railway_api_health.png", "Рисунок 2 — Проверка /api/health")
    add_img(doc, "pb_admin_login.png", "Рисунок 3 — Вход в админку PocketBase")
    add_img(doc, "pb_admin_home.png", "Рисунок 4 — Панель PocketBase после входа")
    add_img(doc, "pb_collections.png", "Рисунок 5 — Список коллекций")
    add_img(doc, "pb_players_records.png", "Рисунок 6 — Коллекция players (сид-данные)")

    add_h(doc, "3. Модель данных")
    add_p(doc, "9 предметных сущностей (+ связующие коллекции PB):")
    add_table(
        doc,
        ["Сущность / коллекция", "Связи"],
        [
            ["users", "auth; role = admin|sponsor|scout"],
            ["arenas", "1:N → teams"],
            ["teams", "arena, sponsor; 1:N → players"],
            ["players", "team; status/notes/price/jersey"],
            ["achievements", "M:N через player_achievements"],
            ["player_achievements", "явная M:N player↔achievement"],
            ["contracts", "1:1 с player (relation)"],
            ["transfer_offers", "player, team, sponsor"],
            ["scout_reports / shortlist_entries", "уникальные разделы скаута"],
        ],
    )
    add_p(
        doc,
        "Подробности: docs/model_logical.md и docs/model_physical.md "
        "(обновлены под строковые id PocketBase и явные M:N/контракты).",
    )

    add_h(doc, "4. Клиент и сеть")
    add_p(
        doc,
        "Слои: models / repositories (Dio + PbClient) / state / screens / widgets. "
        "API_BASE_URL по умолчанию http://127.0.0.1:8090/api; "
        f"для Pages задаётся --dart-define={API_RAILWAY}. "
        "Auth: auth-with-password / auth-refresh, токен в SharedPreferences. "
        "Ошибки PB 400 с полями мапятся на ValidationException / ConflictException; "
        "401 обновляет токен и повторяет запрос.",
    )

    add_h(doc, "5. Роли и доступ")
    add_table(
        doc,
        ["Роль", "Уникальный раздел", "Пример"],
        [
            ["admin", "Пользователи, hard-delete, дашборд", "/users, /dashboard"],
            ["sponsor", "Офферы (+ сводка своих)", "/offers"],
            ["scout", "Отчёты и шортлист", "/scout-reports, /shortlist"],
        ],
    )
    add_img(doc, "app_users.png", "Рисунок 7 — Раздел пользователей (admin)")
    add_img(doc, "app_offers.png", "Рисунок 8 — Офферы (доступ спонсора/админа)")
    add_img(doc, "role_sponsor_users_forbidden.png", "Рисунок 9 — Спонсор: 403 на /users")
    add_img(doc, "role_scout_reports.png", "Рисунок 10 — Скаут: отчёты")
    add_img(doc, "role_scout_shortlist.png", "Рисунок 11 — Скаут: шортлист")
    add_img(doc, "role_scout_offers_forbidden.png", "Рисунок 12 — Скаут: 403 на /offers")

    add_h(doc, "6. Каталог, фильтры, URL")
    add_p(
        doc,
        "Списки игроков/команд/арен/наград/контрактов: поиск, фильтры, сортировка, пагинация, "
        "состояния loading/empty/error/success. Параметры списка синхронизируются с query URL.",
    )
    add_img(doc, "app_players.png", "Рисунок 13 — Каталог игроков")
    add_img(
        doc,
        "app_players_url_filters.png",
        "Рисунок 14 — Игроки с фильтрами в URL (category + sort)",
    )
    add_img(doc, "app_contracts.png", "Рисунок 15 — Контракты")

    add_h(doc, "7. Soft / hard delete и конфликты")
    add_p(
        doc,
        "Мягкое удаление — поле deletedAt; восстановление и физическое удаление — для admin. "
        "Массовые операции — последовательные update/delete по id. "
        "Уникальность номера/email отражается как ConflictException при ответах PB.",
    )

    add_h(doc, "8. Фича п. 20 — дашборд, CSV, диаграммы")
    add_p(
        doc,
        "Раздел /dashboard (admin и sponsor; у спонсора — урезанная сводка по своим офферам). "
        "Карточки: число игроков/офферов, средняя и медианная цена. "
        "Кнопка «Скачать CSV игроков» (клиентская генерация). "
        "Диаграммы fl_chart: распределение по амплуа и по командам.",
    )
    add_img(doc, "app_dashboard.png", "Рисунок 16 — Дашборд администратора")
    add_img(doc, "role_sponsor_dashboard.png", "Рисунок 17 — Сводка спонсора")

    add_h(doc, "9. Тесты, сборка, публикация")
    add_p(doc, "flutter test — 27 тестов (unit + widget). analyze — без error.")
    add_p(
        doc,
        "Сборка для Pages: flutter build web --release --base-href=/YP_CeryakDV/ "
        f"--dart-define=API_BASE_URL={API_RAILWAY}. "
        "Публикация: ветка gh-pages (404.html=index.html), "
        f"репозиторий https://github.com/kon1ac/YP_CeryakDV, сайт {APP_PAGES}. "
        "API на Railway закрывает требование HTTPS для демо с GitHub Pages.",
    )
    add_img(doc, "pages_login.png", "Рисунок 18 — GitHub Pages + Railway API")
    add_p(
        doc,
        "Локально без Railway: PocketBase :8090 + python tools/spa_server.py --port 5555.",
    )

    add_h(doc, "10. Чеклист пунктов 1–20 (кратко)")
    add_table(
        doc,
        ["Блок", "Содержание", "Статус"],
        [
            ["1–8", "Тема, 9 сущностей, CRUD, UI-состояния, адаптив, валидация", "да"],
            ["9–15", "Auth, 3 роли, forbidden, URL-фильтры, сессия", "да"],
            ["16–17", "Soft/hard/restore/bulk, 401/403/409/422 на PB", "да"],
            ["18", "build web + хостинг SPA", "да"],
            ["19", "≥5 widget + ≥8 unit", "да (27)"],
            ["20", "Дашборд + CSV + диаграммы амплуа/команд", "да"],
        ],
    )

    add_h(doc, "11. Вывод")
    add_p(
        doc,
        "Итоговый проект переведён с mock API на PocketBase, сохраняет полный функционал клиента "
        "и закрывает требования оценки «5», включая собственную аналитическую фичу.",
    )

    OUT.parent.mkdir(parents=True, exist_ok=True)
    doc.save(OUT)
    print("wrote", OUT)


if __name__ == "__main__":
    main()
