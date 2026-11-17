# Учебное API «Витрина хоккеистов»

```bash
cd api
node mock-server.js --port 8080 --origin http://localhost:5555
```

Учётки:

| Логин | Пароль | Роль |
|-------|--------|------|
| admin | admin123 | Админ |
| sponsor | sponsor123 | Спонсор |
| scout | scout123 | Скаут |

Без `Authorization` запись и чтение каталога **не** доступны (нужен вход).

Регистрация создаёт пользователя с ролью `scout` (пароль ≥8, цифра и спецсимвол).

Коллекции: `players`, `teams`, `arenas`, `achievements`, `offers` / `transfer-offers`, `scout-reports`, `shortlist`, `users`, виртуальные `contracts`.
