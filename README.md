# Scope Drop

Scope Drop — внутренний сервис для контроля состояния спринтов в YouTrack.
Он сохраняет данные в локальной PostgreSQL и показывает:

- первоначальный план спринта;
- выполненный, добавленный и выпавший объём;
- оставшуюся работу;
- стабильность scope;
- загрузку по разработчикам;
- задачи без оценки;
- задачи, добавленные после старта;
- задачи, снятые из спринта.

YouTrack вызывается только во время синхронизации. Страницы приложения читают
данные из PostgreSQL и не обращаются к YouTrack напрямую.

## Содержание

1. [Возможности](#возможности)
2. [Технологии](#технологии)
3. [Архитектура](#архитектура)
4. [Требования](#требования)
5. [Переменные окружения](#переменные-окружения)
6. [Локальный запуск](#локальный-запуск)
7. [Работа с приложением](#работа-с-приложением)
8. [Правила синхронизации](#правила-синхронизации)
9. [Метрики](#метрики)
10. [REST API](#rest-api)
11. [Модель данных](#модель-данных)
12. [Тесты и проверки](#тесты-и-проверки)
13. [Docker](#docker)
14. [Railway](#railway)
15. [Диагностика](#диагностика)
16. [Безопасность](#безопасность)

## Возможности

### Авторизация

- один общий логин и пароль из ENV;
- cookie-сессия без таблицы пользователей;
- CSRF-защита для изменяющих запросов;
- защита всех внутренних API и frontend-маршрутов;
- выход с завершением сессии.

### Спринты

- список спринтов YouTrack;
- карточка конкретного спринта;
- основные показатели scope;
- показатели по каждому исполнителю;
- полный список задач, включая ранее снятые;
- отдельные выборки задач без оценки, добавленных и снятых.

### Синхронизация

- ручной запуск из интерфейса;
- ежедневный запуск через Railway Cron;
- пагинация запросов YouTrack;
- атомарное применение данных;
- сохранение старых данных при ошибке;
- PostgreSQL advisory lock против параллельных запусков;
- ежедневный агрегированный snapshot.

## Технологии

### Backend

- Ruby 3.4;
- Ruby on Rails 8.1;
- PostgreSQL;
- Puma;
- Minitest.

### Frontend

- React 19;
- TypeScript;
- React Router;
- Vite 8;
- Vitest и Testing Library;
- ESLint.

### Infrastructure

- multi-stage Docker image;
- Railway web service;
- Railway PostgreSQL;
- отдельный Railway Cron service.

## Архитектура

Репозиторий является монорепозиторием:

```text
app/
  controllers/       Rails API и SPA fallback
  models/            Active Record модели
  serializers/       JSON-представление спринтов
  services/
    sprints/          расчёт метрик и snapshots
    you_track/        REST-клиент и синхронизация
db/
  migrate/            миграции PostgreSQL
frontend/
  src/
    components/       общие UI-компоненты
    pages/            Login, список и карточка спринта
    test/             frontend-тесты
lib/tasks/
  scope_drop.rake     ежедневная cron-задача
test/                 backend-тесты
```

В development Rails и Vite работают отдельными процессами:

```text
Browser -> Vite :5173 -> /api proxy -> Rails :3000 -> PostgreSQL
                                           |
                                           +-> YouTrack при синхронизации
```

В production Vite заранее собирает frontend в `public/app`, после чего Rails
раздаёт SPA и REST API с одного origin:

```text
Browser -> Rails/Puma -> SPA + REST API -> PostgreSQL
                              |
                              +-> YouTrack при синхронизации
```

## Требования

Для нативного локального запуска:

- Ruby `3.4.x`;
- Bundler `2.6+`;
- Node.js `24.x`;
- npm `11+`;
- PostgreSQL `16+` или Docker Desktop.

Проверить версии:

```bash
ruby --version
bundle --version
node --version
npm --version
docker --version
```

## Переменные окружения

Создайте локальный файл:

```bash
cp .env.example .env
```

`.env` исключён из Git. Rails не загружает его автоматически, поэтому перед
командами backend необходимо экспортировать переменные:

```bash
set -a
source .env
set +a
```

### Rails и PostgreSQL

| Переменная | Обязательна | Назначение |
| --- | --- | --- |
| `RAILS_ENV` | Нет | Окружение Rails. Локально `development`, в Railway `production`. |
| `DATABASE_URL` | Да | URL подключения к PostgreSQL. |
| `SECRET_KEY_BASE` | Да в production | Подпись и шифрование Rails cookies. |
| `APP_TIME_ZONE` | Нет | Часовой пояс snapshots. По умолчанию `Europe/Moscow`. |

Сгенерировать production-секрет:

```bash
bin/rails secret
```

### Доступ к приложению

| Переменная | Обязательна | Назначение |
| --- | --- | --- |
| `APP_LOGIN` | Да | Общий логин команды. |
| `APP_PASSWORD` | Да | Общий пароль команды. |

### YouTrack

| Переменная | Обязательна | Назначение |
| --- | --- | --- |
| `YOUTRACK_BASE_URL` | Да | Базовый URL без завершающего `/api`. |
| `YOUTRACK_API_TOKEN` | Да | Permanent token без префикса `Bearer`. |
| `YOUTRACK_PROJECT_ID` | Да | Значение для фильтра `project:` в поиске YouTrack. |
| `YOUTRACK_AGILE_BOARD_ID` | Да | ID agile-доски, например `83-7030`. |
| `YOUTRACK_SPRINT_FIELD_NAME` | Нет | Название sprint-поля. По умолчанию `Sprint`. |
| `YOUTRACK_ESTIMATION_FIELD_NAME` | Нет | Поле оценки. По умолчанию `оценка BE`. |
| `YOUTRACK_DONE_STATUS_NAME` | Нет | Завершённый статус. По умолчанию `Done`. |

Правильный формат:

```env
YOUTRACK_BASE_URL=https://youtrack.example.ru
YOUTRACK_API_TOKEN=perm:token-value
YOUTRACK_ESTIMATION_FIELD_NAME="Оценка BE"
```

Не указывайте:

```env
# Неверно: клиент сам добавляет /api и Bearer.
YOUTRACK_BASE_URL=https://youtrack.example.ru/api
YOUTRACK_API_TOKEN="Bearer perm:token-value"
```

## Локальный запуск

### 1. Установка зависимостей

Из корня проекта:

```bash
bundle install
cd frontend
npm install
cd ..
```

### 2. Запуск PostgreSQL в Docker

Первый запуск:

```bash
docker run --name scope-drop-postgres \
  -e POSTGRES_HOST_AUTH_METHOD=trust \
  -e POSTGRES_DB=scope_drop_development \
  -p 5432:5432 \
  -d postgres:16-alpine
```

Для такого контейнера используйте:

```env
DATABASE_URL=postgresql://postgres@127.0.0.1:5432/scope_drop_development
```

Последующие запуски:

```bash
docker start scope-drop-postgres
```

Проверка:

```bash
docker exec scope-drop-postgres pg_isready -U postgres
```

### 3. Подготовка базы

```bash
set -a
source .env
set +a
bin/rails db:prepare
```

Команда создаёт базу при необходимости и применяет миграции.

### 4. Запуск Rails

В первом терминале:

```bash
cd "/Users/islam/Desktop/YouTrack API"
set -a
source .env
set +a
bin/rails server
```

Backend будет доступен по адресу:

```text
http://127.0.0.1:3000
```

Health check:

```bash
curl http://127.0.0.1:3000/up
```

### 5. Запуск frontend

Во втором терминале:

```bash
cd "/Users/islam/Desktop/YouTrack API/frontend"
npm run dev
```

Откройте:

```text
http://127.0.0.1:5173/app/
```

Запросы `/api/*` Vite проксирует на `http://localhost:3000`.

### Остановка

Остановите Rails и Vite сочетанием `Ctrl+C` в соответствующих терминалах.

PostgreSQL:

```bash
docker stop scope-drop-postgres
```

Полностью удалить локальную БД:

```bash
docker rm -f scope-drop-postgres
```

Эта команда удаляет контейнер и его данные.

## Работа с приложением

1. Откройте `/app/`.
2. Войдите по `APP_LOGIN` и `APP_PASSWORD`.
3. Нажмите «Обновить данные».
4. Дождитесь завершения синхронизации.
5. Откройте нужный спринт из таблицы.

До первой успешной синхронизации список спринтов будет пустым.

Если состояние спринта на точную дату старта неизвестно, Initial Scope
фиксируется при первом snapshot после старта. В карточке появляется предупреждение:

```text
Initial Scope определён по первому snapshot.
Историческое состояние на дату старта недоступно.
```

## Правила синхронизации

### Ручной режим

`POST /api/sync`:

1. получает все спринты указанной agile-доски;
2. сохраняет метаданные всех спринтов;
3. для каждого спринта с датами получает задачи;
4. обновляет задачи и связи со спринтом;
5. определяет Initial, Added и Removed scope;
6. рассчитывает метрики;
7. создаёт или обновляет snapshot за текущую дату.

### Ежедневный режим

```bash
bundle exec rake scope_drop:daily_snapshot
```

Ежедневный режим обновляет только активные спринты, дата которых покрывает
текущую дату в `APP_TIME_ZONE`.

### Надёжность

- все данные сначала полностью загружаются из YouTrack;
- изменения применяются внутри одной транзакции PostgreSQL;
- при ошибке YouTrack существующие данные не удаляются;
- одновременно может выполняться только одна синхронизация;
- повторный snapshot за ту же дату обновляет существующую строку.

### Initial Scope

Initial Scope фиксируется один раз:

- `sprint_start` — snapshot сделан в дату старта;
- `first_snapshot` — первый snapshot сделан позже даты старта.

### Added After Start

Задача помечается `is_added_after_start`, если после фиксации Initial Scope она:

- впервые появилась в спринте;
- либо существовала раньше, но отсутствовала в baseline и вернулась позже.

### Removed From Sprint

Если ранее видимая задача исчезла из текущего состава:

- `currently_in_sprint` становится `false`;
- незавершённая задача получает `is_removed_from_sprint = true`;
- завершённая задача сохраняется в истории, но не считается снятой.

При возврате задачи в спринт текущий признак снятия очищается, а исторические
признаки Initial/Added сохраняются.

### Задачи без оценки

Если поле `YOUTRACK_ESTIMATION_FIELD_NAME` пустое:

- задача сохраняется и отображается;
- `has_estimation = false`;
- она учитывается в количестве задач;
- она не участвует в суммах story points.

## Метрики

Все суммы используют только задачи с оценкой.

| Метрика | Формула |
| --- | --- |
| Planned SP | Сумма оценок задач Initial Scope. |
| Completed SP | Сумма оценок всех сохранённых задач со статусом Done. |
| Added SP | Сумма оценок задач, добавленных после baseline. |
| Dropped SP | Сумма незавершённых задач Initial Scope. |
| Remaining SP | Сумма незавершённых задач, которые сейчас находятся в спринте. |
| Completion Rate | `Completed SP / Planned SP * 100`. |
| Scope Drop Rate | `Dropped SP / Planned SP * 100`. |
| Added Scope Rate | `Added SP / Planned SP * 100`. |
| Scope Change Rate | `(Added SP + Dropped SP) / Planned SP * 100`. |
| Scope Stability Index | `max(100 - Scope Change Rate, 0)`. |

Если `Planned SP = 0`, процентные показатели деления возвращают `0`.

Важно: согласно MVP-постановке, Dropped SP включает весь незавершённый Initial
Scope, поэтому во время активного спринта он может пересекаться с Remaining SP.

Показатели по разработчикам рассчитываются по тем же правилам. Задачи без
исполнителя группируются под именем «Без исполнителя».

## REST API

Все ответы имеют формат JSON. Кроме `/api/auth/login` и `/api/auth/me`, методы
требуют активную cookie-сессию.

Изменяющие запросы требуют заголовок:

```text
X-CSRF-Token: <csrf_token из GET /api/auth/me>
```

### Авторизация

#### `GET /api/auth/me`

```json
{
  "authenticated": false,
  "csrf_token": "..."
}
```

#### `POST /api/auth/login`

```json
{
  "login": "admin",
  "password": "password"
}
```

Успех:

```json
{
  "success": true
}
```

Неверные данные: `401 Unauthorized`.

#### `POST /api/auth/logout`

Завершает текущую сессию.

### Синхронизация

#### `POST /api/sync`

Успех:

```json
{
  "status": "success"
}
```

Ошибки:

| HTTP | Код | Значение |
| --- | --- | --- |
| `401` | `unauthorized` | Нет активной сессии. |
| `409` | `sync_in_progress` | Другая синхронизация уже выполняется. |
| `422` | `invalid_csrf_token` | Отсутствует или неверен CSRF token. |
| `502` | `youtrack_sync_failed` | Ошибка запроса или обработки YouTrack. |

### Спринты

#### `GET /api/sprints`

Возвращает спринты по убыванию даты начала:

```json
{
  "items": [
    {
      "id": 1,
      "name": "Sprint 24",
      "start_date": "2026-06-01",
      "end_date": "2026-06-14",
      "archived": false,
      "issues_count": 45,
      "planned_sp": 120,
      "completed_sp": 90,
      "added_sp": 20,
      "dropped_sp": 30,
      "completion_rate": 75,
      "scope_drop_rate": 25,
      "scope_stability_index": 58.4
    }
  ]
}
```

#### `GET /api/sprints/:id`

Возвращает:

- сведения о спринте;
- все метрики;
- показатели по разработчикам;
- задачи и scope-признаки;
- `initial_scope_inferred`.

Несуществующий ID возвращает `404 Not Found`.

### Health check

#### `GET /up`

Используется Railway и Docker smoke-тестами. Успешный ответ имеет статус `200`.

## Модель данных

### `Sprint`

- внешний ID и название;
- даты начала и окончания;
- архивный признак;
- время и источник фиксации Initial Scope.

### `Issue`

- внешний ID и читаемый ключ;
- заголовок и ссылка;
- исполнитель и статус;
- оценка BE;
- признак наличия оценки.

Одна задача может быть связана с несколькими спринтами.

### `SprintIssue`

Связь задачи со спринтом:

- Initial Scope;
- Added After Start;
- Removed From Sprint;
- текущее присутствие в спринте;
- время добавления и снятия.

Комбинация `sprint_id + issue_id` уникальна.

### `SprintDailySnapshot`

Хранит агрегированные показатели спринта за дату:

- суммы SP;
- процентные показатели;
- количество задач;
- количество задач без оценки.

Комбинация `sprint_id + snapshot_date` уникальна.

## Тесты и проверки

### Backend

Тестам нужна PostgreSQL:

```bash
RAILS_ENV=test \
DATABASE_URL=postgresql://postgres@127.0.0.1:5432/scope_drop_test \
bin/rails db:prepare

RAILS_ENV=test \
DATABASE_URL=postgresql://postgres@127.0.0.1:5432/scope_drop_test \
bin/rails test
```

Покрыты:

- все формулы метрик;
- дробные оценки и нулевой план;
- snapshots без дублей;
- пагинация YouTrack;
- baseline, добавление, снятие и возврат задач;
- rollback при ошибке;
- advisory lock;
- авторизация, CSRF и API-коды.

### Ruby style и загрузка классов

```bash
XDG_CACHE_HOME=/private/tmp bin/rubocop
bin/rails zeitwerk:check
```

### Frontend

```bash
cd frontend
npm run lint
npm test
npm run build
npm audit
```

Frontend-тесты проверяют:

- redirect неавторизованного пользователя;
- ошибку логина;
- список спринтов;
- ручную синхронизацию;
- предупреждение inferred Initial Scope;
- отдельные списки задач.

## Docker

Собрать production image:

```bash
docker build -t scope-drop:local .
```

Dockerfile:

1. устанавливает frontend-зависимости через `npm ci`;
2. выполняет production build Vite;
3. устанавливает Ruby gems;
4. копирует SPA в `public/app`;
5. запускает Rails/Puma от непривилегированного пользователя.

Для запуска image нужна доступная PostgreSQL:

```bash
docker run --rm \
  --name scope-drop-web \
  --add-host=host.docker.internal:host-gateway \
  -p 3000:3000 \
  -e DATABASE_URL=postgresql://postgres@host.docker.internal:5432/scope_drop_development \
  -e SECRET_KEY_BASE="$(bin/rails secret)" \
  -e APP_LOGIN=admin \
  -e APP_PASSWORD=change_me \
  -e YOUTRACK_BASE_URL=https://youtrack.example.ru \
  -e YOUTRACK_API_TOKEN=perm:token \
  -e YOUTRACK_PROJECT_ID=PROJECT \
  -e YOUTRACK_AGILE_BOARD_ID=board-id \
  scope-drop:local
```

Production SPA будет доступна на:

```text
http://127.0.0.1:3000/
```

## Railway

### Web service

1. Создайте проект Railway.
2. Добавьте Railway PostgreSQL.
3. Создайте service из этого репозитория.
4. Добавьте production ENV.
5. Используйте `Dockerfile` как builder.

`railway.json` задаёт:

- pre-deploy: `bundle exec rails db:prepare`;
- start: `bundle exec rails server -b 0.0.0.0 -p ${PORT:-3000}`;
- health check: `/up`;
- restart policy при ошибке.

### Cron service

Создайте второй service из того же репозитория и image.

Команда:

```bash
bundle exec rake scope_drop:daily_snapshot
```

Рекомендуемое расписание:

```text
10 21 * * *
```

Railway использует UTC, поэтому это соответствует `00:10` в
`Europe/Moscow`.

Cron service должен получить те же `DATABASE_URL`, YouTrack ENV и
`APP_TIME_ZONE`, что и web service.

## Диагностика

### `role "username" does not exist`

В `DATABASE_URL` отсутствует PostgreSQL-пользователь.

Используйте:

```env
DATABASE_URL=postgresql://postgres@127.0.0.1:5432/scope_drop_development
```

### `connection refused` на порту 5432

Проверьте контейнер:

```bash
docker ps --filter name=scope-drop-postgres
docker start scope-drop-postgres
docker logs scope-drop-postgres
```

### Пустой список спринтов

Проверьте:

- выполнена ли ручная синхронизация;
- правильный ли `YOUTRACK_AGILE_BOARD_ID`;
- содержит ли доска спринты;
- есть ли у permanent token права чтения;
- правильно ли задано sprint-поле;
- есть ли у спринтов даты.

### `youtrack_sync_failed`

Посмотрите Rails logs:

```bash
tail -f log/development.log
```

Частые причины:

- `YOUTRACK_BASE_URL` содержит лишний `/api`;
- token содержит лишний `Bearer`;
- неверный project или board ID;
- имя поля оценки не совпадает с YouTrack;
- YouTrack вернул не-JSON или HTTP error;
- превышен timeout.

### `sync_in_progress`

Уже выполняется ручная или cron-синхронизация. Дождитесь её завершения и
повторите запрос.

### Frontend открывается без данных

Проверьте оба процесса:

```bash
curl http://127.0.0.1:3000/up
curl http://127.0.0.1:5173/api/auth/me
```

Если Rails не работает, Vite загрузит интерфейс, но API-запросы завершатся
ошибкой.

### Сброс development-базы

```bash
set -a
source .env
set +a
bin/rails db:drop db:create db:migrate
```

Команда безвозвратно удалит локальные данные Scope Drop.

## Безопасность

- не коммитьте `.env`;
- не отправляйте permanent token в issue, pull request или чат;
- перевыпускайте token после случайной публикации;
- используйте длинный уникальный `APP_PASSWORD`;
- используйте отдельный production `SECRET_KEY_BASE`;
- выдавайте YouTrack token только с необходимыми правами чтения;
- не передавайте `YOUTRACK_API_TOKEN` frontend-коду;
- в production cookie помечается `Secure`, `HttpOnly` и `SameSite=Lax`;
- чувствительные параметры и authorization headers фильтруются из Rails logs.

## Ограничения MVP

В текущую версию не входят:

- пользователи и роли;
- админка;
- редактирование YouTrack-настроек через UI;
- SSO;
- сравнение спринтов;
- графики истории;
- экспорт CSV/Excel;
- уведомления;
- ручные причины снятия задач;
- полная история каждого изменения задачи.

Эти возможности можно добавлять поверх текущей модели snapshots и
`SprintIssue`.
