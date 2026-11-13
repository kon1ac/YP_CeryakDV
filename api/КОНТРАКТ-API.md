# Контракт учебного API «Хоккейная лига»

Базовый адрес: `http://localhost:8080/api`

## 1. Общие соглашения

- JSON, UTF-8, `Content-Type: application/json` для запросов с телом.
- Списки: `{ "items", "page", "size", "total", "totalPages" }`.
- Ошибка 422: `{ "message": "Ошибка валидации", "errors": { "поле": "текст" } }`.
- Пагинация: `page` (с 1), `size` (1–100, по умолчанию 10), `sort=поле,asc|desc`, `includeDeleted=true`.
- Учебные query: `__delay`, `__fail`.

## 2. Аутентификация

| Метод | Путь | Описание |
|---|---|---|
| POST | `/api/auth/register` | Регистрация (роль `reader`) |
| POST | `/api/auth/login` | Логин → токены |
| POST | `/api/auth/refresh` | Обновление пары токенов |
| GET | `/api/auth/me` | Текущий пользователь (нужен Bearer) |
| POST | `/api/auth/logout` | Отзыв refresh-токена |

**Учётные записи:** `admin/admin123`, `librarian/librarian123`, `reader/reader123`.

**Без заголовка `Authorization`** запросы на создание/изменение/мягкое удаление обрабатываются как роль `librarian` (для удобства в браузере). Hard delete и restore — только с Bearer и ролью `admin`.

## 3. Игроки `/api/players`

| Метод | Путь | Права |
|---|---|---|
| GET | `/api/players` | все |
| GET | `/api/players/{id}` | все |
| POST | `/api/players` | librarian+ |
| PUT | `/api/players/{id}` | librarian+ |
| DELETE | `/api/players/{id}` | soft: librarian+, hard `?hard=true`: admin |
| POST | `/api/players/{id}/restore` | admin |
| POST | `/api/players/bulk-delete` | тело `{ "ids": [], "physical?": bool }` |

**Фильтры списка:** `search`, `category`, `teamId`, `achievementId`, `priceFrom`, `priceTo`, `sort`, `page`, `size`, `includeDeleted`.

**Ответ (развёрнутый):** `team: {id,name}`, `achievements: [{id,name}]`, `contract`, поля игрока.

**Валидация:** уникальный `jerseyNumber` в лиге, уникальный `contract.email`, обязательные `name`, `category`, `teamId`.

## 4. Команды `/api/teams`

CRUD по тому же шаблону, что игроки.

**Фильтры:** `search`, `city`, `arenaId`, `playersFrom`, `playersTo`.

**Ответ:** `arenaName`, `rosterSize` (число активных игроков).

**409 при hard delete:** если есть активные игроки — `{ "message", "count" }`.

## 5. Арены `/api/arenas`

CRUD по шаблону.

**Фильтры:** `search`, `city`, `capacityFrom`, `capacityTo`.

**Ответ:** `teamCount`.

**409 при hard delete:** если есть связанные команды — `{ "message", "count" }`.

## 6. Награды `/api/achievements`

CRUD по шаблону.

**Фильтры:** `search`, `yearFrom`, `yearTo`.

**Ответ:** `holderCount`.

## 7. Контракты `/api/contracts`

Проекция контрактов игроков (отдельной таблицы нет).

| Метод | Путь | Поведение |
|---|---|---|
| GET | `/api/contracts` | Список с пагинацией |
| GET | `/api/contracts/{id}` | По id контракта |
| PUT | `/api/contracts/{id}` | Меняет контракт у владельца |
| DELETE | `/api/contracts/{id}` | soft → soft-delete игрока; `?hard=true` → обнулить `contract` |
| POST | `/api/contracts/{id}/restore` | Восстановить игрока (admin) |
| POST | `/api/contracts/bulk-delete` | `{ "ids", "physical?" }` как у игроков |

**Фильтры:** `search`, `expiringSoon` (или `expiring=true`), `minSalary`, `maxSalary`.

**Запись:** `playerId`, `playerName`, `number`, `email`, `salary`, `signedAt`, `expiresAt`, `deletedAt` (от игрока).

## 8. Служебные

| GET | `/api/__health` | `{ "status": "ok", "time" }` |
| POST | `/api/__reset` | Перечитать `seed.json` |

## 9. CORS

Ответы с `Access-Control-Allow-Origin` из `--origin`. `OPTIONS` → 204.
