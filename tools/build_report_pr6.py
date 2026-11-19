# -*- coding: utf-8 -*-
"""Build Otchet for Practice 6."""
from __future__ import annotations

from pathlib import Path

from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml.ns import qn
from docx.shared import Cm, Pt, RGBColor

ROOT = Path(__file__).resolve().parents[1]
DESK = Path.home() / "OneDrive" / "Рабочий стол" / "report_pr6"
SCREENS = DESK / "screens" if (DESK / "screens").exists() else ROOT / "report_pr6" / "screens"
OUT = DESK / "Otchet_Praktika_6.docx" if DESK.exists() else ROOT / "report_pr6" / "Otchet_Praktika_6.docx"

API_RAILWAY = "https://pocketbase-production-97136057.up.railway.app/api"
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
    last = doc.paragraphs[-1]
    last.alignment = WD_ALIGN_PARAGRAPH.CENTER
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

    add_p(doc, "Практическая работа 6", size=18, bold=True, center=True)
    add_p(
        doc,
        "Адаптивная вёрстка, сборка, публикация и тестирование",
        size=16,
        bold=True,
        center=True,
    )
    add_p(
        doc,
        "Проект: «Витрина хоккейных игроков» (Молодёжка). Клиент — Flutter Web, API — PocketBase.",
        center=True,
        space_after=18,
    )

    add_h(doc, "1. Цель")
    add_p(
        doc,
        "Довести клиент до демонстрационного состояния: адаптив на ширинах 360/768/1280/1920, "
        "релизная сборка, публикация со SPA-fallback, модульные и виджет-тесты, analyze без ошибок.",
    )

    add_h(doc, "2. Адаптивная вёрстка (п. 1)")
    add_p(
        doc,
        "Проверены четыре ширины окна. На 360 px списки показываются карточками, навигация — "
        "горизонтальный скролл с иконками; на 1280+ — таблицы и развёрнутые подписи пунктов меню. "
        "Фильтры собраны через Wrap, формы ограничены ConstrainedBox.",
    )
    add_table(
        doc,
        ["Ширина", "Ожидание", "Результат"],
        [
            ["360", "колонка, карточки, навбар снизу/компактный", "выполнено"],
            ["768", "компактная сетка, без overflow", "выполнено"],
            ["1280", "таблицы, подписи в навигации", "выполнено"],
            ["1920", "контент не растянут бесконтрольно", "выполнено"],
        ],
    )
    add_img(doc, "login_360.png", "Рисунок 1 — Экран входа, ширина 360 px")
    add_img(doc, "players_360.png", "Рисунок 2 — Игроки (карточки), ширина 360 px")
    add_img(doc, "teams_360.png", "Рисунок 3 — Команды (карточки), ширина 360 px")
    add_img(doc, "dashboard_360.png", "Рисунок 4 — Дашборд, ширина 360 px")
    add_img(doc, "players_768.png", "Рисунок 5 — Игроки, ширина 768 px")
    add_img(doc, "players_1280.png", "Рисунок 6 — Игроки (таблица), ширина 1280 px")
    add_img(doc, "dashboard_1280.png", "Рисунок 7 — Дашборд, ширина 1280 px")
    add_img(doc, "player_form_1280.png", "Рисунок 8 — Форма игрока, ширина 1280 px")
    add_img(doc, "players_1920.png", "Рисунок 9 — Игроки, ширина 1920 px")

    add_h(doc, "3. Сборка (п. 2)")
    add_p(doc, "Релизная сборка для GitHub Pages (HTTPS API на Railway):")
    add_p(
        doc,
        "flutter build web --release --base-href=/YP_CeryakDV/ "
        f"--dart-define=API_BASE_URL={API_RAILWAY}",
        size=12,
    )
    add_p(
        doc,
        "Результат — каталог build/web. Адрес API задаётся только через --dart-define "
        "(lib/core/config.dart, String.fromEnvironment), в исходниках нет «зашитого» продакшен-URL. "
        "Для локальной разработки по умолчанию остаётся http://127.0.0.1:8090/api.",
    )
    add_p(doc, "SPA-fallback для GitHub Pages:")
    add_p(doc, "cp build/web/index.html build/web/404.html", size=12)
    add_p(
        doc,
        "Локальная проверка SPA: python tools/spa_server.py --port 5555 "
        "(неизвестный путь отдаёт index.html). Прямой переход /teams после обновления страницы работает.",
    )
    add_img(
        doc,
        "spa_deep_link_teams.png",
        "Рисунок 10 — Прямой URL /teams после SPA-fallback",
    )

    add_h(doc, "4. Сравнение сборок (п. 2.5 / оценка 4–5)")
    add_table(
        doc,
        ["Вариант", "Размер каталога", "Ключевые артефакты"],
        [
            ["Обычный JS", "~35,8 МБ", "main.dart.js ≈ 3,04 МБ"],
            ["--wasm", "~38,4 МБ", "main.dart.wasm ≈ 2,60 МБ + JS fallback"],
            [
                "Оптимизация иконок",
                "MaterialIcons 1,6 МБ → 14 КБ",
                "tree-shake icons при release",
            ],
        ],
    )
    add_p(
        doc,
        "Wasm-сборка чуть больше по суммарному объёму каталога, потому что содержит и Wasm, и JS-fallback. "
        "Размер основного кода Wasm меньше JS-бандла. Дополнительно уменьшен вес шрифтов иконок tree-shaking’ом.",
    )

    add_h(doc, "5. Публикация и хостинг")
    add_p(doc, "Репозиторий: https://github.com/kon1ac/YP_CeryakDV")
    add_p(
        doc,
        "Клиент опубликован в ветке gh-pages скриптом tools/deploy_gh_pages.ps1. "
        f"URL: {APP_PAGES} (источник в настройках GitHub Pages — ветка gh-pages / root).",
    )
    add_p(
        doc,
        "GitHub Pages отдаёт сайт только по HTTPS. Обращение с HTTPS-страницы к локальному HTTP API "
        "браузер блокирует (mixed content). Поэтому PocketBase для демо опубликованной сборки "
        "развёрнут на Railway (HTTPS): "
        "https://pocketbase-production-97136057.up.railway.app "
        f"(health: {API_RAILWAY}/health, админка: …/_/). "
        "Сервис pocketbase в проекте yp-ceryak-pb, данные на volume /pb/pb_data, "
        "схема и сид — pocketbase/remote_setup.py.",
    )
    add_img(doc, "railway_project.png", "Рисунок 11 — Проект PocketBase на Railway")
    add_img(doc, "railway_api_health.png", "Рисунок 12 — HTTPS API /api/health")
    add_img(doc, "pages_login.png", "Рисунок 13 — Вход на GitHub Pages к Railway API")
    add_p(
        doc,
        "Локальный вариант без хостинга API: PocketBase :8090 + SPA :5555. "
        "Для firebase.json добавлены rewrites на /index.html (SPA).",
    )

    add_h(doc, "6. Тестирование (п. 3)")
    add_p(doc, "flutter test — 27 тестов, все зелёные. flutter analyze — без error (есть style info).")
    add_p(doc, "Модульные (≥8): permissions/роли, PlayerQuery, page_parser (PB totalItems), "
          "pb_filter, id_codec, mapHttpError 400→422/409, players CSV.")
    add_p(doc, "Виджетные (≥5): ListLoadingState, ListEmptyState, ListErrorState+retry, "
          "SearchField, EntityPaginator, statusLabel/Format.price.")

    add_h(doc, "7. Соответствие оценкам")
    add_table(
        doc,
        ["Оценка", "Требование", "Статус"],
        [
            ["3", "Адаптив 4 ширины, build web, analyze", "выполнено"],
            ["4", "Публикация, base-href, SPA, dart-define, ≥8 unit, wasm-сравнение", "выполнено"],
            ["5", "≥5 widget tests, оптимизация размера, дашборд как доп. фича итога", "выполнено*"],
        ],
    )
    add_p(
        doc,
        "* Пункты ПР6 про GitHub Actions CI и полный a11y-аудит в этом отчёте не разворачивались отдельно; "
        "основной объём «5» закрыт тестами виджетов, уменьшением ассетов и рабочей публикацией.",
    )

    add_h(doc, "8. Вывод")
    add_p(
        doc,
        "Клиент собран в release, адаптирован под узкие и широкие окна, опубликован с SPA-fallback, "
        "покрыт unit/widget-тестами и работает с PocketBase через --dart-define.",
    )

    OUT.parent.mkdir(parents=True, exist_ok=True)
    doc.save(OUT)
    print("wrote", OUT)


if __name__ == "__main__":
    main()
