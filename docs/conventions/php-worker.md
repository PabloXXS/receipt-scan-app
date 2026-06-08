# Конвенции PHP-воркера (`worker/`)

## Структура и автозагрузка

- PSR-4: namespace `ChekiPrices\Worker\` → `src/`.
- Точка входа — `bin/worker.php` (цикл чтения очереди pgmq).
- Тесты зеркалят `src/` в `tests/` (PHPUnit).
- PHP 8.2+: `declare(strict_types=1)` в каждом файле.

## Очередь

- `JobConsumer` читает `pgmq` с visibility-timeout: успех → `delete`,
  ошибка → инкремент попыток, исчерпание → `archive` + `receipts.status = failed`.

## Провайдер-паттерн (фискальные данные)

- `FiscalProviderInterface::fetchReceipt(QrData): ReceiptData`.
- `FiscalProviderFactory` резолвит провайдера по `country_code` (+ таблица
  `fiscal_providers`). Новая страна = новый класс в `Fiscal/Providers/` + строка
  конфига в `config/providers.php`.

## Пайплайн

- `ReceiptProcessor` оркестрирует шаги `Pipeline/Steps/*` и возвращает
  `ProcessingResult`.

## Доступ к БД и приватность

- Доступ к Supabase только через service-role ключ (`SupabaseClient`).
- Анонимизация изолирована в `Privacy/PriceAnonymizer` и `PublishPricesStep` —
  единственная точка отрыва наблюдений от пользователя (см. `architecture/privacy.md`).

## Документация файла

Каждый файл — с файловым PHPDoc-блоком и PHPDoc на классы/методы по шаблону из
`documentation.md`.
