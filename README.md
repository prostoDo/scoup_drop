# Scope Drop

Scope Drop — локальный сервис для контроля состояния спринтов YouTrack.

Главное ограничение текущей инфраструктуры: YouTrack API доступен только через
корпоративный VPN. Railway не видит YouTrack напрямую, поэтому основной режим
эксплуатации — запуск на ноутбуке, где подключён VPN.

## Что показывает сервис

- плановый объём спринта;
- выполненный объём;
- объём, добавленный после старта;
- невыполненный Initial Scope;
- оставшийся текущий scope;
- стабильность scope;
- загрузку по разработчикам;
- задачи без оценки;
- задачи, добавленные после старта;
- задачи, снятые из спринта.

YouTrack вызывается только во время синхронизации. UI читает данные из локальной
PostgreSQL.

## Основной режим: Local VPN Deployment

Рабочая схема:

```text
Ноутбук + корпоративный VPN
  |
  +-- Browser -> Vite http://127.0.0.1:5173/app/
  |
  +-- Vite proxy /api -> Rails http://127.0.0.1:3000
                         |
                         +-- PostgreSQL Docker :5432
                         |
                         +-- YouTrack API через VPN
```

Сервис предназначен для локального использования владельцем ноутбука. В MVP не
открываем приложение на `0.0.0.0`, не публикуем через ngrok/Cloudflare Tunnel и
не делаем командный публичный доступ.

## Стек

- Ruby 3.4;
- Rails 8.1;
- PostgreSQL 16;
- React 19;
- TypeScript;
- Vite 8;
- React Router;
- Docker Desktop для локальной PostgreSQL.

## Быстрый запуск локально

1. Подключите корпоративный VPN.
2. Проверьте, что Docker Desktop запущен.
3. Заполните `.env`.
4. Выполните:

```bash
cd "/Users/islam/Desktop/YouTrack API"
bin/local-start
```

Скрипт:

- проверит Docker;
- создаст или запустит контейнер `scope-drop-postgres`;
- дождётся готовности PostgreSQL;
- проверит Ruby-зависимости;
- установит frontend-зависимости, если их ещё нет;
- выполнит `bin/rails db:prepare`;
- выведет команды запуска Rails и frontend.

После этого запустите Rails:

```bash
cd "/Users/islam/Desktop/YouTrack API"
set -a
source .env
set +a
bin/rails server
```

В другом терминале запустите frontend:

```bash
cd "/Users/islam/Desktop/YouTrack API/frontend"
npm run dev
```

Откройте:

```text
http://127.0.0.1:5173/app/
```

## Первый запуск вручную

Если нужен запуск без helper-скрипта:

```bash
docker run --name scope-drop-postgres \
  -e POSTGRES_HOST_AUTH_METHOD=trust \
  -e POSTGRES_DB=scope_drop_development \
  -p 5432:5432 \
  -d postgres:16-alpine
```

Для повторного запуска контейнера:

```bash
docker start scope-drop-postgres
```

Подготовка базы:

```bash
cd "/Users/islam/Desktop/YouTrack API"
set -a
source .env
set +a
bin/rails db:prepare
```

Health check Rails:

```bash
curl http://127.0.0.1:3000/up
```

Проверка API через Vite proxy:

```bash
curl http://127.0.0.1:5173/api/auth/me
```

## Переменные окружения

Создайте `.env`:

```bash
cp .env.example .env
```

`.env` не коммитится в Git.

Пример:

```env
RAILS_ENV=development
DATABASE_URL=postgresql://postgres@127.0.0.1:5432/scope_drop_development
SECRET_KEY_BASE=

APP_LOGIN=admin
APP_PASSWORD=change_me
APP_TIME_ZONE=Europe/Moscow

YOUTRACK_BASE_URL=https://youtrack.example.ru
YOUTRACK_API_TOKEN=perm:token-value
YOUTRACK_PROJECT_ID=PROJECT
YOUTRACK_AGILE_BOARD_ID=board-id
YOUTRACK_SPRINT_FIELD_NAME=Sprints
YOUTRACK_ESTIMATION_FIELD_NAME="Оценка BE"
YOUTRACK_DONE_STATUS_NAME=Done
```

Важно:

- `YOUTRACK_BASE_URL` должен быть без завершающего `/api`;
- `YOUTRACK_API_TOKEN` должен быть без слова `Bearer`;
- поля с пробелами нужно брать в кавычки;
- VPN должен быть подключён при ручной синхронизации и daily snapshot.

## Работа с приложением

1. Откройте `http://127.0.0.1:5173/app/`.
2. Войдите по `APP_LOGIN` / `APP_PASSWORD`.
3. Нажмите «Обновить данные».
4. Дождитесь завершения синхронизации.
5. Откройте карточку нужного спринта.

До первой успешной синхронизации список спринтов будет пустым.

## Локальный daily snapshot

Ежедневный snapshot теперь запускается локально на ноутбуке под VPN.

Ручной запуск:

```bash
cd "/Users/islam/Desktop/YouTrack API"
bin/local-snapshot
```

Эквивалентная команда:

```bash
cd "/Users/islam/Desktop/YouTrack API"
set -a
source .env
set +a
bundle exec rake scope_drop:daily_snapshot
```

Условия для успешного запуска:

- ноутбук включён;
- корпоративный VPN подключён;
- контейнер PostgreSQL запущен;
- `.env` заполнен;
- token YouTrack действителен.

### macOS launchd

Создайте файл `~/Library/LaunchAgents/com.scope-drop.snapshot.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.scope-drop.snapshot</string>

  <key>WorkingDirectory</key>
  <string>/Users/islam/Desktop/YouTrack API</string>

  <key>ProgramArguments</key>
  <array>
    <string>/Users/islam/Desktop/YouTrack API/bin/local-snapshot</string>
  </array>

  <key>StartCalendarInterval</key>
  <dict>
    <key>Hour</key>
    <integer>0</integer>
    <key>Minute</key>
    <integer>10</integer>
  </dict>

  <key>StandardOutPath</key>
  <string>/Users/islam/Desktop/YouTrack API/log/local-snapshot.log</string>

  <key>StandardErrorPath</key>
  <string>/Users/islam/Desktop/YouTrack API/log/local-snapshot.error.log</string>
</dict>
</plist>
```

Загрузить задачу:

```bash
launchctl load ~/Library/LaunchAgents/com.scope-drop.snapshot.plist
```

Выгрузить:

```bash
launchctl unload ~/Library/LaunchAgents/com.scope-drop.snapshot.plist
```

Важно: `launchd` не подключает VPN сам. Если VPN выключен, snapshot завершится
ошибкой YouTrack.

### cron

Откройте crontab:

```bash
crontab -e
```

Добавьте:

```cron
10 0 * * * cd "/Users/islam/Desktop/YouTrack API" && ./bin/local-snapshot >> log/local-snapshot.log 2>> log/local-snapshot.error.log
```

## Правила синхронизации

Ручная синхронизация:

```text
POST /api/sync
```

Алгоритм:

1. Получить спринты agile-доски.
2. Выбрать спринты с датами.
3. Для каждого выбранного спринта получить задачи.
4. Применить изменения одной транзакцией PostgreSQL.
5. Обновить задачи и связи.
6. Определить Initial Scope.
7. Определить Added After Start.
8. Определить Removed From Sprint.
9. Рассчитать метрики.
10. Создать или обновить snapshot за текущую дату.

Daily snapshot использует ту же синхронизацию, но обновляет только активные
спринты.

Параллельные синхронизации блокируются через PostgreSQL advisory lock.

## Метрики

Задачи без оценки сохраняются и отображаются, но не участвуют в суммах story
points.

| Метрика | Правило |
| --- | --- |
| Planned SP | Сумма оценок Initial Scope. |
| Completed SP | Сумма оценок задач со статусом `YOUTRACK_DONE_STATUS_NAME`. |
| Added SP | Сумма оценок задач, добавленных после фиксации Initial Scope. |
| Dropped SP | Сумма незавершённых задач Initial Scope. |
| Remaining SP | Сумма незавершённых задач, которые сейчас находятся в спринте. |
| Completion Rate | `Completed SP / Planned SP * 100`. |
| Scope Drop Rate | `Dropped SP / Planned SP * 100`. |
| Added Scope Rate | `Added SP / Planned SP * 100`. |
| Scope Change Rate | `(Added SP + Dropped SP) / Planned SP * 100`. |
| Scope Stability Index | `max(100 - Scope Change Rate, 0)`. |

Если `Planned SP = 0`, процентные показатели возвращают `0`.

Согласно MVP, Dropped SP включает весь незавершённый Initial Scope. Во время
активного спринта он может пересекаться с Remaining SP.

## REST API

### Auth

```text
GET  /api/auth/me
POST /api/auth/login
POST /api/auth/logout
```

`GET /api/auth/me` возвращает CSRF token:

```json
{
  "authenticated": false,
  "csrf_token": "..."
}
```

Изменяющие запросы должны передавать:

```text
X-CSRF-Token: <csrf_token>
```

### Sync

```text
POST /api/sync
```

Ответы:

| HTTP | Ответ |
| --- | --- |
| `200` | `{ "status": "success" }` |
| `401` | `{ "error": "unauthorized" }` |
| `409` | `{ "status": "failed", "error": "sync_in_progress" }` |
| `422` | `{ "error": "invalid_csrf_token" }` |
| `502` | `{ "status": "failed", "error": "youtrack_sync_failed" }` |

### Sprints

```text
GET /api/sprints
GET /api/sprints/:id
```

## Тесты и проверки

Backend:

```bash
RAILS_ENV=test \
DATABASE_URL=postgresql://postgres@127.0.0.1:5432/scope_drop_test \
bin/rails db:prepare

RAILS_ENV=test \
DATABASE_URL=postgresql://postgres@127.0.0.1:5432/scope_drop_test \
bin/rails test
```

Ruby style:

```bash
XDG_CACHE_HOME=/private/tmp bin/rubocop
bin/rails zeitwerk:check
```

Frontend:

```bash
cd frontend
npm run lint
npm test
npm run build
npm audit
```

Smoke checks локального запуска:

```bash
curl http://127.0.0.1:3000/up
curl http://127.0.0.1:5173/api/auth/me
```

## Railway

Railway больше не является основным deployment target для этого MVP.

Причина: Railway не находится внутри корпоративной сети и не может ходить в
YouTrack API без корпоративного VPN. Поэтому:

- не используйте Railway Cron для `scope_drop:daily_snapshot`;
- не рассчитывайте на ручную синхронизацию из Railway web service;
- Railway можно использовать только для UI/БД без прямой синхронизации, если в
  будущем появится отдельный локальный sync-agent.

### Возможное будущее решение

Можно оставить UI и PostgreSQL в Railway, а на ноутбуке под VPN запустить
локальный агент:

```text
Local VPN sync-agent -> YouTrack API
                     -> защищённый ingest API в Railway
                     -> Railway PostgreSQL
```

Это потребует:

- нового защищённого ingest endpoint;
- отдельного API token для агента;
- схемы идемпотентной загрузки payload;
- логов и retry-механизма;
- отдельной модели безопасности.

Для MVP этот вариант не реализован.

## Docker production image

Dockerfile остаётся полезным для production-like проверки:

```bash
docker build -t scope-drop:local .
```

Но сам image не решает VPN-проблему. Если container запускается на машине без
доступа к YouTrack, синхронизация не заработает.

## Диагностика

### YouTrack не синхронизируется

Проверьте:

- VPN подключён;
- `YOUTRACK_BASE_URL` без `/api`;
- `YOUTRACK_API_TOKEN` без `Bearer`;
- token не отозван;
- `YOUTRACK_PROJECT_ID` подходит для поиска `project:`;
- `YOUTRACK_AGILE_BOARD_ID` правильный;
- sprint field и estimation field совпадают с YouTrack.

Посмотреть Rails logs:

```bash
tail -f log/development.log
```

### PostgreSQL не запускается

```bash
docker ps --filter name=scope-drop-postgres
docker logs scope-drop-postgres
docker start scope-drop-postgres
```

Если контейнер повреждён и данные можно удалить:

```bash
docker rm -f scope-drop-postgres
bin/local-start
```

### `role "islam" does not exist`

В `DATABASE_URL` не указан пользователь PostgreSQL.

Используйте:

```env
DATABASE_URL=postgresql://postgres@127.0.0.1:5432/scope_drop_development
```

### Vite открыт, но API не работает

Проверьте Rails:

```bash
curl http://127.0.0.1:3000/up
```

Если Rails не отвечает, frontend загрузится, но API-запросы завершатся ошибкой.

### Сброс локальной базы

```bash
cd "/Users/islam/Desktop/YouTrack API"
set -a
source .env
set +a
bin/rails db:drop db:create db:migrate
```

Команда удалит локальные данные Scope Drop.

## Безопасность

- не коммитьте `.env`;
- не публикуйте YouTrack permanent token;
- если token попал в чат или issue, перевыпустите его;
- используйте отдельный token только с нужными правами чтения;
- не запускайте приложение на `0.0.0.0` без отдельного решения по доступу;
- не включайте публичные туннели в MVP;
- `YOUTRACK_API_TOKEN` никогда не отдаётся на frontend;
- Rails фильтрует пароли, token и authorization headers из логов.

## Ограничения MVP

Не реализованы:

- пользователи и роли;
- админка;
- редактирование YouTrack-настроек через UI;
- SSO;
- сравнение спринтов;
- экспорт CSV/Excel;
- уведомления;
- графики истории;
- sync-agent для Railway;
- публичный командный доступ к локальному UI.
