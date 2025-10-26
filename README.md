# Ticket App — анализ чеков

Приложение для распознавания и структурирования чеков: загрузка фото (камера/галерея), серверный ИИ-анализ и редактирование позиций.

> 🆓 **Новое:** Приложение может работать **полностью бесплатно** с Tesseract OCR!  
> Быстрая настройка: `./setup-free-mode.sh` или см. [FREE_MODE_SETUP.md](FREE_MODE_SETUP.md)

## Платформы

- iOS, Android (актуальные версии ОС)
- Мультиязычность с локализацией (gen-l10n)

## Ключевые возможности

- **Группировка чеков по магазинам** — главная страница показывает магазины с агрегированной информацией
- **Детальный просмотр чеков магазина** — при нажатии на магазин открывается список всех чеков
- Загрузка изображений чеков: камера и галерея (сохранение оригинала)
- Серверный OCR/LLM-анализ (провайдеры TBD)
- Редактирование всех полей чека и позиций
- Поиск и фильтры по магазинам
- Экспорт (CSV/JSON)
- Аутентификация: email magic link, Google, Apple
- Подписка (премиум: расширенная аналитика, анализ цен, статистика)
- Sentry для ошибок

## Архитектура (кратко)

- Flutter + Riverpod + Freezed + GoRouter
- Бэкенд: Supabase (Auth, Postgres, Storage, Edge Functions)
- AI-пайплайн на сервере; мобильный клиент — загрузка, статус, отображение

Подробнее: см. `docs/architecture.md`, `docs/ai_pipeline.md`, `docs/data_model.md`, `docs/security.md`, `docs/api.md`.

## Режимы OCR распознавания

### 🆓 Бесплатный режим (Tesseract)

```bash
./setup-free-mode.sh
```

- **Tesseract OCR** (open-source) на Fly.io Free Tier
- **OCR.space** как fallback (25k бесплатно/мес)
- **Стоимость:** $0/месяц для ~15,000 чеков
- **Точность:** 85-95% на хороших фото

См. [FREE_MODE_SETUP.md](FREE_MODE_SETUP.md)

### 💎 Премиум режим (OpenAI Vision)

```bash
supabase secrets set AI_PROVIDER=openai
supabase secrets set OPENAI_API_KEY=sk-xxx
```

- **OpenAI GPT-4o-mini Vision** (мультимодальная LLM)
- **Tesseract + OCR.space** как fallback
- **Стоимость:** ~$0.01-0.02 за чек
- **Точность:** 95-99% на любых фото

См. [TESSERACT_QUICKSTART.md](TESSERACT_QUICKSTART.md)

## Запуск

1. Требования: Flutter >= 3.22, Dart >= 3.4
2. Переменные окружения:
   - `SUPABASE_URL`, `SUPABASE_ANON_KEY`
   - `SENTRY_DSN` (опц.)
   - `DEFAULT_CURRENCY` (например, RUB)
3. Команды:

```bash
flutter pub get
flutter run
```

Тесты:

```bash
flutter test
```

## Структура

- `lib/` — код приложения (страницы, виджеты, провайдеры)
- `docs/` — документация (архитектура, модель данных, API, безопасность, вклад)
- `ios/`, `android/` — платформенная часть
- `test/` — тесты
- `supabase/` — монорепо для бэкенда (CLI, функции, миграции)

### Monorepo: мобильный + Supabase

1. Установка Supabase CLI

```bash
brew install supabase/tap/supabase # macOS
```

2. Конфиг

- `supabase/config.toml` — заполните `project_id` (ref проекта из Dashboard)

3. Миграции

```bash
supabase db reset --use-migra
```

4. Секреты функций

```bash
supabase secrets set \
  SUPABASE_URL='https://<ref>.supabase.co' \
  SUPABASE_SERVICE_ROLE_KEY='<service_role>' \
  SUPABASE_ANON_KEY='<anon>' \
  OPENAI_API_KEY='<openai>'
```

5. Локальный запуск/деплой Edge Functions

```bash
supabase functions serve analyze
supabase functions deploy analyze
supabase functions deploy status
```

## Документация

- `docs/architecture.md` — архитектура и технологии
- `docs/data_model.md` — таблицы и схемы
- `docs/ai_pipeline.md` — пайплайн OCR/LLM
- `docs/api.md` — серверные эндпоинты/функции
- `docs/security.md` — безопасность и приватность
- `docs/contributing.md` — вклад и стиль

## Лицензия

TBD
