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

## Команды

- `composer install`
- `composer validate`
- `php bin/worker.php`
- `vendor/bin/phpunit`

## Документация файла

Каждый `.php`-файл — файловый PHPDoc-блок + PHPDoc на классы/методы
(шаблон в `../docs/conventions/documentation.md`).
