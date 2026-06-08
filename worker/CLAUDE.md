# PHP-воркер ChekiPrices (`worker/`)

Конвенции этого подпроекта. Полные правила — `../docs/conventions/php-worker.md`.

## Структура

- PSR-4: `ChekiPrices\Worker\` → `src/`. Тесты — `ChekiPrices\Worker\Tests\` → `tests/`.
- Точка входа: `bin/worker.php` (цикл чтения очереди pgmq).
- PHP 8.2+: `declare(strict_types=1)` в каждом файле.

## Ключевые правила

- Очередь: `JobConsumer` читает `pgmq` с visibility-timeout (успех → delete,
  ошибка → retry, исчерпание → archive + `receipts.status = failed`).
- Фискальные провайдеры: `FiscalProviderFactory` по `country_code`; новая страна =
  новый класс в `src/Fiscal/Providers/` + строка в `config/providers.php`.
- Доступ к БД — только service-role (`SupabaseClient`).
- Анонимизация — только в `Privacy/PriceAnonymizer` и `PublishPricesStep`.

## Best practices (PHP 8.2+)

- `declare(strict_types=1)` в каждом файле; строгая типизация параметров и возвратов.
- DTO — `readonly`-классы (`Fiscal/Dto/*`), неизменяемые; без бизнес-логики в данных.
- Шаги пайплайна (`Pipeline/Steps/*`) — единичная ответственность; оркестрация только
  в `ReceiptProcessor`; результат — `ProcessingResult`.
- Зависимости — через конструктор (DI), а не глобальные/статические синглтоны.
- Ошибки не «глотать»: исключения доходят до статуса чека (`failed`) и архива очереди.
- Логи — через PSR-3 (`Support/Logger`); не логировать секреты и service-role ключ.
- Стиль — PSR-12.

## Качество и CI

- Локально (если установлен PHP): `composer validate --strict`,
  `find src bin config -name '*.php' -exec php -l {} \;`, `vendor/bin/phpunit`.
- **PHP может быть не установлен на машине** — полную проверку гарантирует CI
  (`.github/workflows/ci.yml`, job `worker`): validate → install → `php -l` → phpunit.
- Изменения цен/анонимизации проверяй субагентом `privacy-rls-reviewer`; общий код
  воркера — `php-worker-reviewer`.

## Команды

- `composer install`
- `composer validate`
- `php bin/worker.php`
- `vendor/bin/phpunit`

## Документация файла

Каждый `.php`-файл — файловый PHPDoc-блок + PHPDoc на классы/методы
(шаблон в `../docs/conventions/documentation.md`).
