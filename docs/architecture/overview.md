# Архитектура — обзор

ChekiPrices состоит из трёх компонентов.

```
┌─────────────┐      ┌──────────────────────────┐      ┌──────────────┐
│   Flutter    │      │         Supabase          │      │  PHP Worker   │
│  (Riverpod,  │◄────►│  Postgres + RLS + Auth +  │◄────►│  (демон,      │
│ clean layers)│      │  Storage + Realtime +     │      │  очередь pgmq)│
└─────────────┘      │  pgmq                     │      └──────┬───────┘
                      └──────────────────────────┘             │
                                                      ┌─────────▼─────────┐
                                                      │ Фискальные провайд.│
                                                      │ (страна→стратегия) │
                                                      │  + OCR fallback    │
                                                      └────────────────────┘
```

## Компоненты

- **Flutter (`app/`)** — клиент: Riverpod (codegen) + чистая слоистая
  архитектура, feature-first. Зависимости направлены внутрь:
  `presentation → domain ← data`.
- **Supabase** — Postgres с RLS, Auth (email+пароль и OAuth Google/Apple),
  Storage (фото чеков), Realtime (статус обработки), очередь `pgmq`.
- **PHP-воркер (`worker/`)** — долгоживущий демон: читает очередь, по стране
  выбирает фискального провайдера, тянет состав чека, при неудаче — OCR-fallback,
  нормализует товары, публикует обезличенные цены.

## Навигация (клиент)

После входа — нижнее меню (Material 3 `NavigationBar`) с 4 разделами: **Чеки,
Статистика, Скан, Профиль**. Реализовано через `GoRouter StatefulShellRoute.indexedStack`
(оболочка `app/lib/core/navigation/main_shell.dart`); каждая вкладка — отдельная ветка со
своим стеком навигации и сохранением состояния. Auth-экраны — вне оболочки; `redirect`
(`core/router/auth_redirect.dart`) уводит авторизованного на `/receipts`, неавторизованного
— на `/sign-in`. Выход из аккаунта — на вкладке «Профиль».

См. также `data-flow.md` (поток чека), `data-model.md` (схема), `privacy.md`
(приватность), `adr/0001-pgmq-queue.md` (почему pgmq).
