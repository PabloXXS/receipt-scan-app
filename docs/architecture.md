# Архитектура

## Стек

- Клиент: Flutter 3.22+, Dart 3.4+, Riverpod, Freezed, GoRouter, gen-l10n, Sentry
- Бэкенд: Supabase (Auth, Postgres, Storage, Edge Functions)
- AI: OCR и LLM — провайдеры TBD (серверная сторона)

## Слои

- Presentation: виджеты (ConsumerWidget/HookConsumerWidget), навигация GoRouter, состояния AsyncValue
- Domain: иммутабельные модели (Freezed), use-cases
- Data: Supabase репозитории (Auth, Storage, DB), кэш при необходимости

## Навигация

- Основные экраны: `Home`, `Search`, `Profile`, `ReceiptDetails`, `Scan`
- Deep links поддерживаются (GoRouter)

## Локализация и тема

- gen-l10n, поддержка нескольких языков
- Светлая/темная темы

## Производительность/офлайн

- Очередь загрузок офлайн, ретраи (экспоненциальный backoff)
- Цель: P95 от съемки до результата < 10 c (TBD)

## Аналитика и ошибки

- Sentry (ошибки), базовые события (TBD)
