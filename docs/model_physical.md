# Физическая модель (mock API / будущий SQLite·PocketBase)

Коллекции = таблицы. PK — целочисленный `id`. Мягкое удаление — `deletedAt` (NULL = активна).

## users

| Поле | Тип | Ограничения |
|------|-----|-------------|
| id | INTEGER PK | |
| username | TEXT | UNIQUE, NOT NULL, ≥3 |
| passwordHash | TEXT | NOT NULL |
| fullName | TEXT | NOT NULL |
| email | TEXT | |
| role | TEXT | admin \| sponsor \| scout |
| createdAt | TEXT (ISO) | |
| deletedAt | TEXT NULL | |

Индекс: `username`.

## arenas

| Поле | Тип |
|------|-----|
| id | INTEGER PK |
| name, city | TEXT NOT NULL |
| capacity | INTEGER > 0 |
| createdAt, deletedAt | TEXT |

## teams

| Поле | Тип |
|------|-----|
| id | INTEGER PK |
| name, city | TEXT NOT NULL |
| foundedYear | INTEGER |
| arenaId | INTEGER FK → arenas.id |
| sponsorUserId | INTEGER NULL FK → users.id |
| createdAt, deletedAt | TEXT |

Индексы: `arenaId`, `sponsorUserId`.

## players

| Поле | Тип |
|------|-----|
| id | INTEGER PK |
| name, description, category | TEXT |
| price | REAL ≥ 0 |
| teamId | INTEGER FK → teams.id |
| jerseyNumber | INTEGER NULL 1..99 UNIQUE among active |
| status | TEXT NOT NULL | in_roster \| injured \| suspended \| free_agent |
| notes | TEXT NULL | ≤2000 |
| achievementIds | JSON array of INT | M:N к achievements |
| contract | JSON NULL | вложенный объект (1:1) |
| createdAt, deletedAt | TEXT |

Индексы: `teamId`, `status`, `category`, `price`.

### contract (вложено / логическая таблица contracts)

| Поле | Тип |
|------|-----|
| id | INTEGER |
| number | INTEGER |
| email | TEXT |
| salary | REAL |
| signedAt, expiresAt | TEXT |

## achievements

| Поле | Тип |
|------|-----|
| id | INTEGER PK |
| name, description | TEXT |
| year | INTEGER |
| createdAt, deletedAt | TEXT |

## transfer_offers

| Поле | Тип |
|------|-----|
| id | INTEGER PK |
| playerId | INTEGER FK → players.id |
| teamId | INTEGER FK → teams.id |
| sponsorUserId | INTEGER FK → users.id |
| salary | REAL ≥ 0 |
| message | TEXT |
| status | TEXT | pending \| accepted \| rejected |
| createdAt, deletedAt | TEXT |

Индексы: `playerId`, `teamId`, `sponsorUserId`, `status`.

## scout_reports

| Поле | Тип |
|------|-----|
| id | INTEGER PK |
| playerId | INTEGER FK → players.id |
| scoutUserId | INTEGER FK → users.id |
| rating | INTEGER 1..10 |
| verdict | TEXT | recommend \| watch \| reject |
| summary | TEXT NOT NULL ≤2000 |
| createdAt, deletedAt | TEXT |

## shortlist_entries

| Поле | Тип |
|------|-----|
| id | INTEGER PK |
| scoutUserId | INTEGER FK → users.id |
| playerId | INTEGER FK → players.id |
| note | TEXT |
| createdAt, deletedAt | TEXT |
| UNIQUE(scoutUserId, playerId) where deletedAt IS NULL | |

## REST-пути mock API

- `/api/users` (admin)
- `/api/arenas|teams|players|achievements`
- `/api/contracts` (виртуальная выборка)
- `/api/transfer-offers`
- `/api/scout-reports`
- `/api/shortlist`
- `/api/auth/*`

Черновик SQL (для будущего PocketBase/SQLite) — те же имена таблиц в snake_case: `transfer_offers`, `scout_reports`, `shortlist_entries`, `player_achievements(player_id, achievement_id)`.
