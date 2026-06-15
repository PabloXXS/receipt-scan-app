# Тонкий PHP-воркер: OCR-сервис → receipt_items → review — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Реализовать заглушки PHP-воркера так, чтобы он по сообщению из pgmq скачивал фото чека, вызывал OCR-сервис (план №1), писал распознанные позиции с confidence в `receipt_items` и переводил чек в `status=review` (или `failed`).

**Architecture:** Тонкий оркестратор. Доступ к БД/очереди — **только PostgREST с service-role** (`SupabaseClient` поверх guzzle); pgmq доступен через public RPC-обёртки (мигр. 0009), гранты только `service_role`. Шаг OCR скачивает фото из Storage и POST'ит в OCR-сервис, который возвращает готовые позиции. Фискальный путь пока заглушён `NullProvider` — основной путь OCR. Это план №3 из 4.

**Tech Stack:** PHP 8.2, guzzlehttp/guzzle (HTTP/PostgREST/Storage/OCR), vlucas/phpdotenv, monolog, PHPUnit 11. PostgreSQL/pgmq на стороне Supabase.

**⚠️ Верификация:** PHP/Composer **локально не установлены** ([no-php-runtime]). Тесты PHPUnit **нельзя прогнать локально** — они верифицируются в CI (`.github/workflows/ci.yml`, job `worker`). Локальные гейты качества: (1) субагент `php-worker-reviewer`, (2) синтаксис миграции — на dev через Supabase MCP. Каждая «PHP»-задача: написать тест + реализацию, верификация — CI. Шаги «прогнать тест» означают «в CI».

**Инвариант приватности:** воркер пишет только зону A (`receipt_items`, `receipts`). В зону C ничего не публикует (PublishPricesStep вне этого плана). Доступ к БД — только service-role. Изменения проверяет `php-worker-reviewer`; миграцию 0009 — `privacy-rls-reviewer`.

---

## Файлы

- Create: `supabase/migrations/0009_worker_confidence_pgmq_rpc.sql` — confidence-колонка + pgmq RPC-обёртки.
- Modify: `worker/composer.json` — добавить скрипт `test`.
- Create: `worker/.env.example` — список env-переменных.
- Modify: `worker/src/Support/Config.php` — типизированные геттеры (int/обязательные).
- Modify: `worker/src/Fiscal/Dto/ItemData.php` — поле `confidence`.
- Modify: `worker/src/Supabase/SupabaseClient.php` — реализация PostgREST + Storage download.
- Modify: `worker/src/Queue/PgmqClient.php` — read/delete/archive через RPC.
- Modify: `worker/src/Supabase/ReceiptRepository.php` — get/insert items/update status.
- Create: `worker/src/Ocr/OcrServiceClient.php` — HTTP-клиент OCR-сервиса.
- Modify: `worker/src/Pipeline/Steps/OcrFallbackStep.php` — основной OCR-шаг (Storage → OCR-сервис → ReceiptData).
- Modify: `worker/src/Pipeline/Steps/FetchFiscalDataStep.php` — Null-путь.
- Modify: `worker/src/Pipeline/Steps/PersistReceiptStep.php` — запись позиций + статус.
- Modify: `worker/src/Pipeline/ReceiptProcessor.php` — оркестрация.
- Modify: `worker/src/Queue/JobConsumer.php` — цикл read→process→delete|retry/archive.
- Modify: `worker/bin/worker.php` — wiring + цикл.
- Create: `worker/tests/...` — PHPUnit на каждый компонент.
- Modify: `docs/features/scan.md`, `docs/architecture/data-flow.md` — серверный async-путь воркера.

---

### Task 1: Миграция 0009 — confidence-колонка + pgmq RPC-обёртки

**Files:**
- Create: `supabase/migrations/0009_worker_confidence_pgmq_rpc.sql`

- [ ] **Step 1: Написать миграцию**

```sql
-- Миграция: worker — confidence на позициях + public RPC-обёртки pgmq (service_role).
-- Зона доступа: A (receipt_items). pgmq-обёртки — служебные, только service_role.
-- Инвариант приватности: зона A/служебная очередь; в зону C ничего не уходит.

-- 1. Уверенность распознавания позиции (для подсветки в ревью на клиенте).
alter table public.receipt_items
  add column if not exists confidence numeric(4, 3);

-- 2. RPC-обёртки pgmq для воркера (PostgREST не отдаёт схему pgmq напрямую).
--    Доступ строго service_role; revoke с anon/authenticated.

create or replace function public.pgmq_read_jobs(
  p_queue text,
  p_vt integer,
  p_qty integer
)
returns table (msg_id bigint, read_ct integer, message jsonb)
language sql
security definer
set search_path = pgmq, public, pg_temp
as $$
  select msg_id, read_ct, message
  from pgmq.read(p_queue, p_vt, p_qty);
$$;

create or replace function public.pgmq_delete_job(p_queue text, p_msg_id bigint)
returns boolean
language sql
security definer
set search_path = pgmq, public, pg_temp
as $$
  select pgmq.delete(p_queue, p_msg_id);
$$;

create or replace function public.pgmq_archive_job(p_queue text, p_msg_id bigint)
returns boolean
language sql
security definer
set search_path = pgmq, public, pg_temp
as $$
  select pgmq.archive(p_queue, p_msg_id);
$$;

revoke execute on function public.pgmq_read_jobs(text, integer, integer) from public, anon, authenticated;
revoke execute on function public.pgmq_delete_job(text, bigint) from public, anon, authenticated;
revoke execute on function public.pgmq_archive_job(text, bigint) from public, anon, authenticated;
grant execute on function public.pgmq_read_jobs(text, integer, integer) to service_role;
grant execute on function public.pgmq_delete_job(text, bigint) to service_role;
grant execute on function public.pgmq_archive_job(text, bigint) to service_role;
```

- [ ] **Step 2: Применить на dev через Supabase MCP**

MCP `apply_migration`: project_id `yftrsgcqrzzmxbttlltz`, name `0009_worker_confidence_pgmq_rpc`, query = файл.
Expected: `{"success": true}`.

- [ ] **Step 3: Проверить объекты (MCP execute_sql)**

```sql
select column_name, data_type from information_schema.columns
 where table_schema='public' and table_name='receipt_items' and column_name='confidence';
select proname, prosecdef from pg_proc p join pg_namespace n on n.oid=p.pronamespace
 where n.nspname='public' and proname like 'pgmq_%_job%' or proname='pgmq_read_jobs';
```
Expected: колонка `confidence numeric`; три функции `pgmq_read_jobs/pgmq_delete_job/pgmq_archive_job` с `prosecdef=true`.

- [ ] **Step 4: Smoke-тест очереди (MCP execute_sql, транзакция с rollback)**

```sql
begin;
select pgmq.send('receipts_processing', jsonb_build_object('receipt_id','00000000-0000-0000-0000-0000000000ff'));
select msg_id, read_ct, message->>'receipt_id' as rid from public.pgmq_read_jobs('receipts_processing', 30, 10);
rollback;
```
Expected: одна строка с `rid = 00000000-...00ff`. (rollback откатит тестовое сообщение.)

- [ ] **Step 5: privacy-rls-reviewer на миграцию**

Запустить субагент `privacy-rls-reviewer` на `0009_worker_confidence_pgmq_rpc.sql`: confidence — зона A; pgmq-обёртки `SECURITY DEFINER` с фиксированным search_path, грант только `service_role`, зона C не затронута.

- [ ] **Step 6: Commit**

```bash
git add supabase/migrations/0009_worker_confidence_pgmq_rpc.sql
git commit -m "feat(db): receipt_items.confidence and service-role pgmq RPC wrappers"
```

---

### Task 2: Конфиг, env и поле confidence в ItemData

**Files:**
- Modify: `worker/composer.json`
- Create: `worker/.env.example`
- Modify: `worker/src/Support/Config.php`
- Modify: `worker/src/Fiscal/Dto/ItemData.php`
- Test: `worker/tests/Support/ConfigTest.php`, `worker/tests/Fiscal/Dto/ItemDataTest.php`

- [ ] **Step 1: Добавить confidence в ItemData (+ тест)**

`worker/tests/Fiscal/Dto/ItemDataTest.php`:
```php
<?php
declare(strict_types=1);

namespace ChekiPrices\Worker\Tests\Fiscal\Dto;

use ChekiPrices\Worker\Fiscal\Dto\ItemData;
use PHPUnit\Framework\TestCase;

final class ItemDataTest extends TestCase
{
    public function testHoldsConfidenceAndBarcode(): void
    {
        $i = new ItemData('Молоко', 1.0, 2.5, 2.5, 0.92, '4811');
        self::assertSame('Молоко', $i->rawName);
        self::assertSame(0.92, $i->confidence);
        self::assertSame('4811', $i->barcode);
    }

    public function testConfidenceAndBarcodeNullable(): void
    {
        $i = new ItemData('X', 1.0, 1.0, 1.0);
        self::assertNull($i->confidence);
        self::assertNull($i->barcode);
    }
}
```

`worker/src/Fiscal/Dto/ItemData.php` — добавить поля:
```php
final readonly class ItemData
{
    public function __construct(
        public string $rawName,
        public float $qty,
        public float $unitPrice,
        public float $sum,
        public ?float $confidence = null,
        public ?string $barcode = null,
    ) {
    }
}
```

- [ ] **Step 2: Типизированные геттеры Config (+ тест)**

`worker/tests/Support/ConfigTest.php`:
```php
<?php
declare(strict_types=1);

namespace ChekiPrices\Worker\Tests\Support;

use ChekiPrices\Worker\Support\Config;
use PHPUnit\Framework\TestCase;

final class ConfigTest extends TestCase
{
    public function testRequireReturnsValue(): void
    {
        $_ENV['CFG_X'] = 'hello';
        self::assertSame('hello', (new Config())->require('CFG_X'));
    }

    public function testRequireThrowsWhenMissing(): void
    {
        unset($_ENV['CFG_MISSING']);
        $this->expectException(\RuntimeException::class);
        (new Config())->require('CFG_MISSING');
    }

    public function testIntWithDefault(): void
    {
        unset($_ENV['CFG_INT']);
        self::assertSame(30, (new Config())->int('CFG_INT', 30));
        $_ENV['CFG_INT'] = '5';
        self::assertSame(5, (new Config())->int('CFG_INT', 30));
    }
}
```

Дополнить `worker/src/Support/Config.php` методами (оставив существующий `get`):
```php
    /** Обязательная переменная; бросает, если не задана. */
    public function require(string $key): string
    {
        $v = $this->get($key);
        if ($v === null || $v === '') {
            throw new \RuntimeException("Missing required env: {$key}");
        }
        return $v;
    }

    /** Целочисленная переменная со значением по умолчанию. */
    public function int(string $key, int $default): int
    {
        $v = $this->get($key);
        return $v === null || $v === '' ? $default : (int) $v;
    }
```

- [ ] **Step 3: .env.example**

`worker/.env.example`:
```
# Supabase (service-role — НИКОГДА не коммитить реальный ключ)
SUPABASE_URL=https://<project>.supabase.co
SUPABASE_SERVICE_ROLE_KEY=

# OCR-сервис (план №1)
OCR_SERVICE_URL=http://ocr-service:8000

# Очередь
QUEUE_NAME=receipts_processing
QUEUE_VISIBILITY_TIMEOUT=60
QUEUE_BATCH=5
QUEUE_MAX_ATTEMPTS=5
WORKER_SLEEP_SECONDS=5

# Storage
RECEIPTS_BUCKET=receipts
```

- [ ] **Step 4: composer-скрипт test**

В `worker/composer.json` добавить блок `scripts`:
```json
    "scripts": {
        "test": "phpunit --colors=always",
        "lint": "find src bin config -name '*.php' -print0 | xargs -0 -n1 php -l"
    }
```
И создать `worker/phpunit.xml`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         bootstrap="vendor/autoload.php" colors="true">
  <testsuites>
    <testsuite name="worker">
      <directory>tests</directory>
    </testsuite>
  </testsuites>
</phpunit>
```

- [ ] **Step 5: Commit**

```bash
git add worker/composer.json worker/phpunit.xml worker/.env.example worker/src/Support/Config.php worker/src/Fiscal/Dto/ItemData.php worker/tests/Support/ConfigTest.php worker/tests/Fiscal/Dto/ItemDataTest.php
git commit -m "feat(worker): config getters, ItemData confidence/barcode, phpunit setup"
```

---

### Task 3: SupabaseClient — PostgREST + Storage download

**Files:**
- Modify: `worker/src/Supabase/SupabaseClient.php`
- Test: `worker/tests/Supabase/SupabaseClientTest.php`

Клиент поверх guzzle. Конструктор принимает `GuzzleHttp\ClientInterface` (для тестов через MockHandler). Методы: `request()` (PostgREST JSON), `rpc()` (POST /rest/v1/rpc/{fn}), `downloadObject()` (Storage, сырые байты).

- [ ] **Step 1: Тест с MockHandler**

`worker/tests/Supabase/SupabaseClientTest.php`:
```php
<?php
declare(strict_types=1);

namespace ChekiPrices\Worker\Tests\Supabase;

use ChekiPrices\Worker\Supabase\SupabaseClient;
use GuzzleHttp\Client;
use GuzzleHttp\Handler\MockHandler;
use GuzzleHttp\HandlerStack;
use GuzzleHttp\Psr7\Response;
use GuzzleHttp\Psr7\Request;
use PHPUnit\Framework\TestCase;

final class SupabaseClientTest extends TestCase
{
    /** @var list<Request> */
    private array $recorded = [];

    private function client(MockHandler $mock): SupabaseClient
    {
        $stack = HandlerStack::create($mock);
        $stack->push(\GuzzleHttp\Middleware::history($this->recorded));
        $http = new Client(['handler' => $stack]);
        return new SupabaseClient('https://x.supabase.co', 'svc-key', $http);
    }

    public function testRpcSendsServiceRoleHeadersAndDecodesJson(): void
    {
        $mock = new MockHandler([new Response(200, [], '[{"msg_id":7}]')]);
        $client = $this->client($mock);

        $out = $client->rpc('pgmq_read_jobs', ['p_queue' => 'q', 'p_vt' => 30, 'p_qty' => 5]);

        self::assertSame([['msg_id' => 7]], $out);
        $req = $this->recorded[0]['request'];
        self::assertSame('POST', $req->getMethod());
        self::assertStringContainsString('/rest/v1/rpc/pgmq_read_jobs', (string) $req->getUri());
        self::assertSame('svc-key', $req->getHeaderLine('apikey'));
        self::assertSame('Bearer svc-key', $req->getHeaderLine('Authorization'));
    }

    public function testDownloadObjectReturnsRawBytes(): void
    {
        $mock = new MockHandler([new Response(200, [], "\xFF\xD8\xFFbytes")]);
        $client = $this->client($mock);

        $bytes = $client->downloadObject('receipts', 'uid/ts.jpg');

        self::assertSame("\xFF\xD8\xFFbytes", $bytes);
        $req = $this->recorded[0]['request'];
        self::assertStringContainsString('/storage/v1/object/receipts/uid/ts.jpg', (string) $req->getUri());
        self::assertSame('Bearer svc-key', $req->getHeaderLine('Authorization'));
    }
}
```

- [ ] **Step 2: Реализация SupabaseClient**

```php
<?php
declare(strict_types=1);

/**
 * Назначение: PostgREST/Storage-клиент поверх service-role ключа.
 *
 * Роль в пайплайне: единственный канал доступа воркера к БД/Storage (зоны A/B).
 * Зависимости: guzzlehttp/guzzle.
 */

namespace ChekiPrices\Worker\Supabase;

use GuzzleHttp\ClientInterface;

final class SupabaseClient
{
    public function __construct(
        private readonly string $url,
        private readonly string $serviceRoleKey,
        private readonly ClientInterface $http,
    ) {
    }

    /** @return array<string,string> */
    private function headers(): array
    {
        return [
            'apikey' => $this->serviceRoleKey,
            'Authorization' => 'Bearer ' . $this->serviceRoleKey,
            'Content-Type' => 'application/json',
        ];
    }

    /**
     * PostgREST-запрос к таблице/представлению.
     *
     * @param array<string,mixed> $options доп. опции guzzle (query/json/headers)
     * @return array<int|string,mixed>
     */
    public function request(string $method, string $path, array $options = []): array
    {
        $options['headers'] = array_merge($this->headers(), $options['headers'] ?? []);
        $resp = $this->http->request($method, $this->url . '/rest/v1/' . ltrim($path, '/'), $options);
        $body = (string) $resp->getBody();
        if ($body === '') {
            return [];
        }
        /** @var array<int|string,mixed> $decoded */
        $decoded = json_decode($body, true, 512, JSON_THROW_ON_ERROR);
        return $decoded;
    }

    /**
     * Вызов RPC-функции (POST /rest/v1/rpc/{fn}).
     *
     * @param array<string,mixed> $args
     * @return array<int|string,mixed>
     */
    public function rpc(string $function, array $args = []): array
    {
        return $this->request('POST', 'rpc/' . $function, ['json' => $args]);
    }

    /** Скачивает объект Storage (сырые байты). */
    public function downloadObject(string $bucket, string $path): string
    {
        $resp = $this->http->request(
            'GET',
            $this->url . '/storage/v1/object/' . $bucket . '/' . ltrim($path, '/'),
            ['headers' => ['Authorization' => 'Bearer ' . $this->serviceRoleKey, 'apikey' => $this->serviceRoleKey]],
        );
        return (string) $resp->getBody();
    }
}
```

- [ ] **Step 3: Verify (CI)** — `composer test` в CI зелёный (тест SupabaseClientTest). Локально не прогнать.

- [ ] **Step 4: Commit**

```bash
git add worker/src/Supabase/SupabaseClient.php worker/tests/Supabase/SupabaseClientTest.php
git commit -m "feat(worker): SupabaseClient PostgREST/Storage over service-role"
```

---

### Task 4: PgmqClient через RPC-обёртки

**Files:**
- Modify: `worker/src/Queue/PgmqClient.php`
- Test: `worker/tests/Queue/PgmqClientTest.php`

- [ ] **Step 1: Тест (мок SupabaseClient)**

`worker/tests/Queue/PgmqClientTest.php`:
```php
<?php
declare(strict_types=1);

namespace ChekiPrices\Worker\Tests\Queue;

use ChekiPrices\Worker\Queue\PgmqClient;
use ChekiPrices\Worker\Supabase\SupabaseClient;
use PHPUnit\Framework\TestCase;

final class PgmqClientTest extends TestCase
{
    public function testReadMapsRpcRows(): void
    {
        $supabase = $this->createMock(SupabaseClient::class);
        $supabase->expects(self::once())->method('rpc')
            ->with('pgmq_read_jobs', ['p_queue' => 'q', 'p_vt' => 30, 'p_qty' => 2])
            ->willReturn([
                ['msg_id' => 7, 'read_ct' => 1, 'message' => ['receipt_id' => 'r1']],
            ]);

        $jobs = (new PgmqClient($supabase))->read('q', 30, 2);

        self::assertCount(1, $jobs);
        self::assertSame(7, $jobs[0]['msg_id']);
        self::assertSame(1, $jobs[0]['read_ct']);
        self::assertSame('r1', $jobs[0]['message']['receipt_id']);
    }

    public function testDeleteAndArchiveCallRpc(): void
    {
        $supabase = $this->createMock(SupabaseClient::class);
        $supabase->expects(self::exactly(2))->method('rpc')
            ->willReturnCallback(function (string $fn, array $args): array {
                self::assertContains($fn, ['pgmq_delete_job', 'pgmq_archive_job']);
                self::assertSame(['p_queue' => 'q', 'p_msg_id' => 7], $args);
                return [];
            });

        $c = new PgmqClient($supabase);
        $c->delete('q', 7);
        $c->archive('q', 7);
    }
}
```

- [ ] **Step 2: Реализация PgmqClient**

```php
<?php
declare(strict_types=1);

/**
 * Назначение: клиент очереди pgmq через PostgREST RPC-обёртки (service-role).
 *
 * Роль в пайплайне: транспорт задач между Postgres-триггером и воркером.
 * Зависимости: Supabase\SupabaseClient (RPC pgmq_read_jobs/pgmq_delete_job/pgmq_archive_job).
 */

namespace ChekiPrices\Worker\Queue;

use ChekiPrices\Worker\Supabase\SupabaseClient;

final class PgmqClient
{
    public function __construct(private readonly SupabaseClient $supabase)
    {
    }

    /**
     * @return list<array{msg_id:int, read_ct:int, message:array<string,mixed>}>
     */
    public function read(string $queue, int $visibilityTimeout, int $limit = 1): array
    {
        $rows = $this->supabase->rpc('pgmq_read_jobs', [
            'p_queue' => $queue,
            'p_vt' => $visibilityTimeout,
            'p_qty' => $limit,
        ]);
        $jobs = [];
        foreach ($rows as $row) {
            /** @var array{msg_id:int,read_ct:int,message:array<string,mixed>} $row */
            $jobs[] = [
                'msg_id' => (int) $row['msg_id'],
                'read_ct' => (int) $row['read_ct'],
                'message' => (array) $row['message'],
            ];
        }
        return $jobs;
    }

    public function delete(string $queue, int $msgId): void
    {
        $this->supabase->rpc('pgmq_delete_job', ['p_queue' => $queue, 'p_msg_id' => $msgId]);
    }

    public function archive(string $queue, int $msgId): void
    {
        $this->supabase->rpc('pgmq_archive_job', ['p_queue' => $queue, 'p_msg_id' => $msgId]);
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add worker/src/Queue/PgmqClient.php worker/tests/Queue/PgmqClientTest.php
git commit -m "feat(worker): PgmqClient via service-role RPC wrappers"
```

---

### Task 5: OcrServiceClient + OcrFallbackStep (Storage → OCR-сервис → ReceiptData)

**Files:**
- Create: `worker/src/Ocr/OcrServiceClient.php`
- Modify: `worker/src/Pipeline/Steps/OcrFallbackStep.php`
- Test: `worker/tests/Ocr/OcrServiceClientTest.php`, `worker/tests/Pipeline/Steps/OcrFallbackStepTest.php`

OCR-сервис (план №1) возвращает `{items:[{raw_name,qty,unit_price,sum,confidence,barcode}], total, confidence}`. `OcrServiceClient` шлёт байты фото и парсит JSON в `ReceiptData`. `OcrFallbackStep` качает фото из Storage и вызывает клиент.

- [ ] **Step 1: Тест OcrServiceClient (MockHandler)**

`worker/tests/Ocr/OcrServiceClientTest.php`:
```php
<?php
declare(strict_types=1);

namespace ChekiPrices\Worker\Tests\Ocr;

use ChekiPrices\Worker\Ocr\OcrServiceClient;
use GuzzleHttp\Client;
use GuzzleHttp\Handler\MockHandler;
use GuzzleHttp\HandlerStack;
use GuzzleHttp\Psr7\Response;
use PHPUnit\Framework\TestCase;

final class OcrServiceClientTest extends TestCase
{
    public function testParsesItemsIntoReceiptData(): void
    {
        $json = json_encode([
            'items' => [
                ['raw_name' => 'Молоко', 'qty' => 1, 'unit_price' => 2.5, 'sum' => 2.5,
                 'confidence' => 0.9, 'barcode' => '4811'],
                ['raw_name' => 'Хлеб', 'qty' => 2, 'unit_price' => 1.25, 'sum' => 2.5,
                 'confidence' => 0.8, 'barcode' => null],
            ],
            'total' => 5.0,
            'confidence' => 0.85,
        ]);
        $http = new Client(['handler' => HandlerStack::create(new MockHandler([new Response(200, [], $json)]))]);

        $receipt = (new OcrServiceClient('http://ocr:8000', $http))->recognize("\xFF\xD8jpeg");

        self::assertSame(5.0, $receipt->total);
        self::assertCount(2, $receipt->items);
        self::assertSame('Молоко', $receipt->items[0]->rawName);
        self::assertSame(0.9, $receipt->items[0]->confidence);
        self::assertSame(2.0, $receipt->items[1]->qty);
    }
}
```

- [ ] **Step 2: Реализация OcrServiceClient**

```php
<?php
declare(strict_types=1);

/**
 * Назначение: HTTP-клиент OCR-сервиса (фото → распознанные позиции).
 *
 * Роль в пайплайне: используется OcrFallbackStep; превращает ответ OCR-сервиса
 * (план №1) в ReceiptData.
 * Зависимости: guzzlehttp/guzzle, Fiscal\Dto\{ReceiptData,ItemData}.
 */

namespace ChekiPrices\Worker\Ocr;

use ChekiPrices\Worker\Fiscal\Dto\ItemData;
use ChekiPrices\Worker\Fiscal\Dto\ReceiptData;
use GuzzleHttp\ClientInterface;

final class OcrServiceClient
{
    public function __construct(
        private readonly string $baseUrl,
        private readonly ClientInterface $http,
    ) {
    }

    /** Распознаёт позиции по байтам фото через OCR-сервис. */
    public function recognize(string $photoBytes): ReceiptData
    {
        $resp = $this->http->request('POST', rtrim($this->baseUrl, '/') . '/ocr', [
            'multipart' => [[
                'name' => 'photo',
                'contents' => $photoBytes,
                'filename' => 'receipt.jpg',
                'headers' => ['Content-Type' => 'image/jpeg'],
            ]],
        ]);
        /** @var array{items:list<array<string,mixed>>,total:?float,confidence:float} $data */
        $data = json_decode((string) $resp->getBody(), true, 512, JSON_THROW_ON_ERROR);

        $items = [];
        foreach ($data['items'] as $it) {
            $items[] = new ItemData(
                rawName: (string) $it['raw_name'],
                qty: (float) ($it['qty'] ?? 1),
                unitPrice: (float) ($it['unit_price'] ?? 0),
                sum: (float) ($it['sum'] ?? 0),
                confidence: isset($it['confidence']) ? (float) $it['confidence'] : null,
                barcode: isset($it['barcode']) ? ($it['barcode'] !== null ? (string) $it['barcode'] : null) : null,
            );
        }
        return new ReceiptData(
            storeExternalId: null,
            purchasedAt: null,
            total: isset($data['total']) ? (float) $data['total'] : null,
            currency: null,
            items: $items,
        );
    }
}
```

- [ ] **Step 3: Тест OcrFallbackStep (моки)**

`worker/tests/Pipeline/Steps/OcrFallbackStepTest.php`:
```php
<?php
declare(strict_types=1);

namespace ChekiPrices\Worker\Tests\Pipeline\Steps;

use ChekiPrices\Worker\Fiscal\Dto\ReceiptData;
use ChekiPrices\Worker\Ocr\OcrServiceClient;
use ChekiPrices\Worker\Pipeline\Steps\OcrFallbackStep;
use ChekiPrices\Worker\Supabase\SupabaseClient;
use PHPUnit\Framework\TestCase;

final class OcrFallbackStepTest extends TestCase
{
    public function testDownloadsPhotoAndCallsOcr(): void
    {
        $supabase = $this->createMock(SupabaseClient::class);
        $supabase->expects(self::once())->method('downloadObject')
            ->with('receipts', 'uid/ts.jpg')->willReturn("\xFF\xD8jpeg");

        $expected = new ReceiptData(null, null, 5.0, null, []);
        $ocr = $this->createMock(OcrServiceClient::class);
        $ocr->expects(self::once())->method('recognize')->with("\xFF\xD8jpeg")->willReturn($expected);

        $step = new OcrFallbackStep($ocr, $supabase, 'receipts');
        self::assertSame($expected, $step->run('uid/ts.jpg'));
    }
}
```

- [ ] **Step 4: Реализация OcrFallbackStep**

```php
<?php
declare(strict_types=1);

/**
 * Назначение: основной OCR-шаг — фото из Storage → OCR-сервис → ReceiptData.
 *
 * Роль в пайплайне: шаг распознавания ReceiptProcessor (фискального API пока нет).
 * Зависимости: Ocr\OcrServiceClient, Supabase\SupabaseClient, Fiscal\Dto\ReceiptData.
 */

namespace ChekiPrices\Worker\Pipeline\Steps;

use ChekiPrices\Worker\Fiscal\Dto\ReceiptData;
use ChekiPrices\Worker\Ocr\OcrServiceClient;
use ChekiPrices\Worker\Supabase\SupabaseClient;

final class OcrFallbackStep
{
    public function __construct(
        private readonly OcrServiceClient $ocr,
        private readonly SupabaseClient $supabase,
        private readonly string $bucket,
    ) {
    }

    /** Распознаёт позиции по фото чека (путь в Storage). */
    public function run(string $photoPath): ReceiptData
    {
        $bytes = $this->supabase->downloadObject($this->bucket, $photoPath);
        return $this->ocr->recognize($bytes);
    }
}
```

- [ ] **Step 5: Commit**

```bash
git add worker/src/Ocr/OcrServiceClient.php worker/src/Pipeline/Steps/OcrFallbackStep.php worker/tests/Ocr/OcrServiceClientTest.php worker/tests/Pipeline/Steps/OcrFallbackStepTest.php
git commit -m "feat(worker): OCR service client and OCR step (Storage to positions)"
```

---

### Task 6: ReceiptRepository — get / insert items / update status

**Files:**
- Modify: `worker/src/Supabase/ReceiptRepository.php`
- Test: `worker/tests/Supabase/ReceiptRepositoryTest.php`

Методы: `getPhotoPath(receiptId): ?string`; `replaceItems(receiptId, ItemData[])`; `markReview(receiptId, ?total)`; `markFailed(receiptId, error)`. Запись через PostgREST с service-role (минует RLS).

- [ ] **Step 1: Тест (мок SupabaseClient)**

`worker/tests/Supabase/ReceiptRepositoryTest.php`:
```php
<?php
declare(strict_types=1);

namespace ChekiPrices\Worker\Tests\Supabase;

use ChekiPrices\Worker\Fiscal\Dto\ItemData;
use ChekiPrices\Worker\Supabase\ReceiptRepository;
use ChekiPrices\Worker\Supabase\SupabaseClient;
use PHPUnit\Framework\TestCase;

final class ReceiptRepositoryTest extends TestCase
{
    public function testGetPhotoPathReturnsValue(): void
    {
        $supabase = $this->createMock(SupabaseClient::class);
        $supabase->method('request')->willReturn([['photo_path' => 'uid/ts.jpg', 'user_id' => 'u1']]);
        $repo = new ReceiptRepository($supabase);
        self::assertSame('uid/ts.jpg', $repo->getPhotoPath('r1'));
    }

    public function testGetPhotoPathNullWhenMissing(): void
    {
        $supabase = $this->createMock(SupabaseClient::class);
        $supabase->method('request')->willReturn([]);
        self::assertNull((new ReceiptRepository($supabase))->getPhotoPath('r1'));
    }

    public function testMarkReviewPatchesStatusAndTotal(): void
    {
        $supabase = $this->createMock(SupabaseClient::class);
        $supabase->expects(self::once())->method('request')
            ->with('PATCH', self::stringContains('receipts?id=eq.r1'), self::callback(function ($opts) {
                return $opts['json'] === ['status' => 'review', 'total' => 5.0];
            }))->willReturn([]);
        (new ReceiptRepository($supabase))->markReview('r1', 5.0);
    }
}
```

- [ ] **Step 2: Реализация ReceiptRepository**

```php
<?php
declare(strict_types=1);

/**
 * Назначение: доступ воркера к receipts/receipt_items (service-role, PostgREST).
 *
 * Роль в пайплайне: чтение photo_path, запись позиций и статуса.
 * Зависимости: Supabase\SupabaseClient, Fiscal\Dto\ItemData.
 */

namespace ChekiPrices\Worker\Supabase;

use ChekiPrices\Worker\Fiscal\Dto\ItemData;

final class ReceiptRepository
{
    public function __construct(private readonly SupabaseClient $supabase)
    {
    }

    /** Путь фото чека в Storage (или null). */
    public function getPhotoPath(string $receiptId): ?string
    {
        $rows = $this->supabase->request('GET', 'receipts', [
            'query' => ['id' => 'eq.' . $receiptId, 'select' => 'photo_path', 'limit' => 1],
        ]);
        $path = $rows[0]['photo_path'] ?? null;
        return $path === null ? null : (string) $path;
    }

    /**
     * Заменяет позиции чека (удаляет старые, вставляет новые).
     *
     * @param list<ItemData> $items
     */
    public function replaceItems(string $receiptId, array $items): void
    {
        $this->supabase->request('DELETE', 'receipt_items', [
            'query' => ['receipt_id' => 'eq.' . $receiptId],
        ]);
        if ($items === []) {
            return;
        }
        $rows = array_map(static fn (ItemData $i): array => [
            'receipt_id' => $receiptId,
            'raw_name' => $i->rawName,
            'qty' => $i->qty,
            'unit_price' => $i->unitPrice,
            'sum' => $i->sum,
            'confidence' => $i->confidence,
        ], $items);
        // user_id/family_id проставит триггер receipt_items_fill_owner? Нет — он берёт
        // auth.uid(); под service-role он null. Поэтому проставляем user_id явно из чека.
        $this->supabase->request('POST', 'receipt_items', ['json' => $rows]);
    }

    /** Переводит чек в review с пересчитанным итогом. */
    public function markReview(string $receiptId, ?float $total): void
    {
        $this->supabase->request('PATCH', 'receipts?id=eq.' . $receiptId, [
            'json' => ['status' => 'review', 'total' => $total],
        ]);
    }

    /** Помечает чек как failed с текстом ошибки. */
    public function markFailed(string $receiptId, string $error): void
    {
        $this->supabase->request('PATCH', 'receipts?id=eq.' . $receiptId, [
            'json' => ['status' => 'failed', 'error' => $error],
        ]);
    }
}
```

> ⚠️ **Важно для исполнителя (вскрылось при написании):** триггер `receipt_items_fill_owner`
> ставит `user_id := auth.uid()`, но под service-role `auth.uid()` = null, а колонка
> `user_id` — NOT NULL. Значит воркер обязан проставлять `user_id` (и `family_id`) в
> receipt_items сам. `getPhotoPath` нужно расширить до `getOwner` (вернуть `user_id`,
> `family_id`, `photo_path` одним запросом), и `replaceItems` принимать `user_id`/
> `family_id`. Скорректируй сигнатуры в этой задаче: `getReceiptContext(receiptId):
> array{user_id,family_id,photo_path}` и `replaceItems(receiptId, userId, familyId, items)`.
> Тесты обнови соответственно. Это часть данной задачи — не оставляй несоответствие.

- [ ] **Step 3: Commit**

```bash
git add worker/src/Supabase/ReceiptRepository.php worker/tests/Supabase/ReceiptRepositoryTest.php
git commit -m "feat(worker): ReceiptRepository read context, replace items, status updates"
```

---

### Task 7: FetchFiscalDataStep (Null) + PersistReceiptStep + ReceiptProcessor

**Files:**
- Modify: `worker/src/Pipeline/Steps/FetchFiscalDataStep.php`
- Modify: `worker/src/Pipeline/Steps/PersistReceiptStep.php`
- Modify: `worker/src/Pipeline/ReceiptProcessor.php`
- Test: `worker/tests/Pipeline/PersistReceiptStepTest.php`, `worker/tests/Pipeline/ReceiptProcessorTest.php`

`ReceiptProcessor` на текущем этапе: получить контекст чека (owner + photo_path) → OCR-шаг → Persist (review). Фискальный шаг не вызывается (OCR — основной путь); `FetchFiscalDataStep` приводим к рабочему Null-состоянию, но в процессоре его не используем (оставляем зависимость для будущего, помечаем).

- [ ] **Step 1: PersistReceiptStep — тест**

`worker/tests/Pipeline/PersistReceiptStepTest.php`:
```php
<?php
declare(strict_types=1);

namespace ChekiPrices\Worker\Tests\Pipeline;

use ChekiPrices\Worker\Fiscal\Dto\ItemData;
use ChekiPrices\Worker\Fiscal\Dto\ReceiptData;
use ChekiPrices\Worker\Pipeline\Steps\PersistReceiptStep;
use ChekiPrices\Worker\Supabase\ReceiptRepository;
use PHPUnit\Framework\TestCase;

final class PersistReceiptStepTest extends TestCase
{
    public function testWritesItemsAndMarksReviewWithComputedTotal(): void
    {
        $items = [
            new ItemData('A', 1, 2.0, 2.0, 0.9),
            new ItemData('B', 1, 3.0, 3.0, 0.8),
        ];
        $receipt = new ReceiptData(null, null, null, null, $items); // total отсутствует → считаем сами

        $repo = $this->createMock(ReceiptRepository::class);
        $repo->expects(self::once())->method('replaceItems')
            ->with('r1', 'u1', null, $items);
        $repo->expects(self::once())->method('markReview')->with('r1', 5.0);

        (new PersistReceiptStep($repo))->run('r1', 'u1', null, $receipt);
    }

    public function testUsesPrintedTotalWhenPresent(): void
    {
        $items = [new ItemData('A', 1, 2.0, 2.0)];
        $receipt = new ReceiptData(null, null, 9.99, null, $items);
        $repo = $this->createMock(ReceiptRepository::class);
        $repo->method('replaceItems');
        $repo->expects(self::once())->method('markReview')->with('r1', 9.99);
        (new PersistReceiptStep($repo))->run('r1', 'u1', null, $receipt);
    }
}
```

- [ ] **Step 2: PersistReceiptStep — реализация**

```php
<?php
declare(strict_types=1);

/**
 * Назначение: записать receipt_items и перевести чек в review.
 *
 * Роль в пайплайне: финальный шаг ReceiptProcessor (успешный путь).
 * Зависимости: Supabase\ReceiptRepository, Fiscal\Dto\ReceiptData.
 */

namespace ChekiPrices\Worker\Pipeline\Steps;

use ChekiPrices\Worker\Fiscal\Dto\ReceiptData;
use ChekiPrices\Worker\Supabase\ReceiptRepository;

final class PersistReceiptStep
{
    public function __construct(private readonly ReceiptRepository $receipts)
    {
    }

    /** Сохраняет позиции и ставит статус review. */
    public function run(string $receiptId, string $userId, ?string $familyId, ReceiptData $receipt): void
    {
        $this->receipts->replaceItems($receiptId, $userId, $familyId, $receipt->items);
        $total = $receipt->total ?? $this->sumItems($receipt);
        $this->receipts->markReview($receiptId, $total);
    }

    private function sumItems(ReceiptData $receipt): ?float
    {
        if ($receipt->items === []) {
            return null;
        }
        $sum = 0.0;
        foreach ($receipt->items as $i) {
            $sum += $i->sum;
        }
        return round($sum, 2);
    }
}
```

- [ ] **Step 3: FetchFiscalDataStep — Null-путь**

```php
<?php
declare(strict_types=1);

/**
 * Назначение: фискальный шаг (пока заглушён — фискального API в РБ нет).
 *
 * Роль в пайплайне: зарезервирован под будущий фискальный путь; сейчас возвращает
 * пустой ReceiptData (основной путь — OCR).
 * Зависимости: Fiscal\FiscalProviderFactory, Fiscal\Dto\*.
 */

namespace ChekiPrices\Worker\Pipeline\Steps;

use ChekiPrices\Worker\Fiscal\Dto\QrData;
use ChekiPrices\Worker\Fiscal\Dto\ReceiptData;
use ChekiPrices\Worker\Fiscal\FiscalProviderFactory;

final class FetchFiscalDataStep
{
    public function __construct(
        private readonly FiscalProviderFactory $factory,
    ) {
    }

    /** Пока возвращает пустой состав чека (фискального API нет). */
    public function run(QrData $qr): ReceiptData
    {
        return new ReceiptData(null, null, null, null, []);
    }
}
```

- [ ] **Step 4: ReceiptProcessor — тест**

`worker/tests/Pipeline/ReceiptProcessorTest.php`:
```php
<?php
declare(strict_types=1);

namespace ChekiPrices\Worker\Tests\Pipeline;

use ChekiPrices\Worker\Fiscal\Dto\ItemData;
use ChekiPrices\Worker\Fiscal\Dto\ReceiptData;
use ChekiPrices\Worker\Pipeline\ReceiptProcessor;
use ChekiPrices\Worker\Pipeline\Steps\OcrFallbackStep;
use ChekiPrices\Worker\Pipeline\Steps\PersistReceiptStep;
use ChekiPrices\Worker\Supabase\ReceiptRepository;
use PHPUnit\Framework\TestCase;

final class ReceiptProcessorTest extends TestCase
{
    public function testProcessesReceiptToReview(): void
    {
        $repo = $this->createMock(ReceiptRepository::class);
        $repo->method('getReceiptContext')->with('r1')
            ->willReturn(['user_id' => 'u1', 'family_id' => null, 'photo_path' => 'uid/ts.jpg']);

        $receipt = new ReceiptData(null, null, 5.0, null, [new ItemData('A', 1, 5.0, 5.0)]);
        $ocr = $this->createMock(OcrFallbackStep::class);
        $ocr->method('run')->with('uid/ts.jpg')->willReturn($receipt);

        $persist = $this->createMock(PersistReceiptStep::class);
        $persist->expects(self::once())->method('run')->with('r1', 'u1', null, $receipt);

        $result = (new ReceiptProcessor($ocr, $persist, $repo))->process('r1');
        self::assertSame('review', $result->status);
    }

    public function testMissingPhotoMarksFailed(): void
    {
        $repo = $this->createMock(ReceiptRepository::class);
        $repo->method('getReceiptContext')->willReturn(['user_id' => 'u1', 'family_id' => null, 'photo_path' => null]);
        $repo->expects(self::once())->method('markFailed')->with('r1', self::stringContains('photo'));

        $ocr = $this->createMock(OcrFallbackStep::class);
        $persist = $this->createMock(PersistReceiptStep::class);

        $result = (new ReceiptProcessor($ocr, $persist, $repo))->process('r1');
        self::assertSame('failed', $result->status);
    }
}
```

- [ ] **Step 5: ReceiptProcessor — реализация**

> Конструктор меняем на актуальные зависимости (OCR-шаг, Persist, Repository). Прежние
> поля (FetchFiscalDataStep/NormalizeItemsStep/PublishPricesStep) убираем из этого
> плана — нормализация и публикация цен вне его объёма.

```php
<?php
declare(strict_types=1);

/**
 * Назначение: оркестратор обработки одного чека (OCR → запись → review).
 *
 * Роль в пайплайне: вызывается JobConsumer.
 * Зависимости: Steps\OcrFallbackStep, Steps\PersistReceiptStep, Supabase\ReceiptRepository.
 */

namespace ChekiPrices\Worker\Pipeline;

use ChekiPrices\Worker\Pipeline\Steps\OcrFallbackStep;
use ChekiPrices\Worker\Pipeline\Steps\PersistReceiptStep;
use ChekiPrices\Worker\Supabase\ReceiptRepository;

final class ReceiptProcessor
{
    public function __construct(
        private readonly OcrFallbackStep $ocr,
        private readonly PersistReceiptStep $persist,
        private readonly ReceiptRepository $receipts,
    ) {
    }

    /** Обрабатывает чек: распознаёт позиции и ставит review (или failed). */
    public function process(string $receiptId): ProcessingResult
    {
        $ctx = $this->receipts->getReceiptContext($receiptId);
        $photoPath = $ctx['photo_path'] ?? null;
        if ($photoPath === null) {
            $this->receipts->markFailed($receiptId, 'no photo_path for OCR');
            return new ProcessingResult('failed', 'no photo_path');
        }
        $data = $this->ocr->run($photoPath);
        $this->persist->run($receiptId, (string) $ctx['user_id'], $ctx['family_id'], $data);
        return new ProcessingResult('review');
    }
}
```

- [ ] **Step 6: Commit**

```bash
git add worker/src/Pipeline/ worker/tests/Pipeline/
git commit -m "feat(worker): receipt processor orchestration to review status"
```

---

### Task 8: JobConsumer цикл + bin/worker.php wiring

**Files:**
- Modify: `worker/src/Queue/JobConsumer.php`
- Modify: `worker/bin/worker.php`
- Test: `worker/tests/Queue/JobConsumerTest.php`

`tick`: читает пачку, для каждого — `process(receipt_id)`; успех → `delete`; исключение → если `read_ct >= maxAttempts` → `markFailed` + `archive`, иначе оставляем (visibility-timeout вернёт позже).

- [ ] **Step 1: Тест JobConsumer**

`worker/tests/Queue/JobConsumerTest.php`:
```php
<?php
declare(strict_types=1);

namespace ChekiPrices\Worker\Tests\Queue;

use ChekiPrices\Worker\Pipeline\ProcessingResult;
use ChekiPrices\Worker\Pipeline\ReceiptProcessor;
use ChekiPrices\Worker\Queue\JobConsumer;
use ChekiPrices\Worker\Queue\PgmqClient;
use ChekiPrices\Worker\Supabase\ReceiptRepository;
use PHPUnit\Framework\TestCase;

final class JobConsumerTest extends TestCase
{
    public function testDeletesMessageOnSuccess(): void
    {
        $queue = $this->createMock(PgmqClient::class);
        $queue->method('read')->willReturn([
            ['msg_id' => 7, 'read_ct' => 1, 'message' => ['receipt_id' => 'r1']],
        ]);
        $queue->expects(self::once())->method('delete')->with('q', 7);

        $processor = $this->createMock(ReceiptProcessor::class);
        $processor->method('process')->with('r1')->willReturn(new ProcessingResult('review'));

        $repo = $this->createMock(ReceiptRepository::class);

        (new JobConsumer($queue, $processor, $repo, 'q', 5))->tick(30, 5);
    }

    public function testArchivesAndFailsAfterMaxAttempts(): void
    {
        $queue = $this->createMock(PgmqClient::class);
        $queue->method('read')->willReturn([
            ['msg_id' => 7, 'read_ct' => 5, 'message' => ['receipt_id' => 'r1']],
        ]);
        $queue->expects(self::once())->method('archive')->with('q', 7);
        $queue->expects(self::never())->method('delete');

        $processor = $this->createMock(ReceiptProcessor::class);
        $processor->method('process')->willThrowException(new \RuntimeException('boom'));

        $repo = $this->createMock(ReceiptRepository::class);
        $repo->expects(self::once())->method('markFailed')->with('r1', self::stringContains('boom'));

        (new JobConsumer($queue, $processor, $repo, 'q', 5))->tick(30, 5);
    }

    public function testLeavesMessageForRetryBeforeMaxAttempts(): void
    {
        $queue = $this->createMock(PgmqClient::class);
        $queue->method('read')->willReturn([
            ['msg_id' => 7, 'read_ct' => 2, 'message' => ['receipt_id' => 'r1']],
        ]);
        $queue->expects(self::never())->method('archive');
        $queue->expects(self::never())->method('delete');

        $processor = $this->createMock(ReceiptProcessor::class);
        $processor->method('process')->willThrowException(new \RuntimeException('temp'));

        $repo = $this->createMock(ReceiptRepository::class);
        $repo->expects(self::never())->method('markFailed');

        (new JobConsumer($queue, $processor, $repo, 'q', 5))->tick(30, 5);
    }
}
```

- [ ] **Step 2: Реализация JobConsumer**

```php
<?php
declare(strict_types=1);

/**
 * Назначение: цикл обработки очереди — read → process → delete | retry/archive.
 *
 * Роль в пайплайне: верхнеуровневый драйвер; вызывает ReceiptProcessor.
 * Зависимости: PgmqClient, Pipeline\ReceiptProcessor, Supabase\ReceiptRepository.
 */

namespace ChekiPrices\Worker\Queue;

use ChekiPrices\Worker\Pipeline\ReceiptProcessor;
use ChekiPrices\Worker\Supabase\ReceiptRepository;

final class JobConsumer
{
    public function __construct(
        private readonly PgmqClient $queue,
        private readonly ReceiptProcessor $processor,
        private readonly ReceiptRepository $receipts,
        private readonly string $queueName,
        private readonly int $maxAttempts,
    ) {
    }

    /** Один проход: читает пачку и обрабатывает каждое сообщение. */
    public function tick(int $visibilityTimeout, int $batch): void
    {
        foreach ($this->queue->read($this->queueName, $visibilityTimeout, $batch) as $job) {
            $receiptId = (string) ($job['message']['receipt_id'] ?? '');
            try {
                if ($receiptId === '') {
                    throw new \RuntimeException('job without receipt_id');
                }
                $this->processor->process($receiptId);
                $this->queue->delete($this->queueName, $job['msg_id']);
            } catch (\Throwable $e) {
                if ($job['read_ct'] >= $this->maxAttempts) {
                    if ($receiptId !== '') {
                        $this->receipts->markFailed($receiptId, $e->getMessage());
                    }
                    $this->queue->archive($this->queueName, $job['msg_id']);
                }
                // иначе оставляем сообщение: vt истечёт и оно вернётся для ретрая
            }
        }
    }
}
```

- [ ] **Step 3: bin/worker.php — wiring**

```php
<?php
declare(strict_types=1);

/**
 * Назначение: точка входа воркера — загрузка окружения, wiring, цикл pgmq.
 *
 * Роль в пайплайне: процесс-демон; на каждом проходе вызывает JobConsumer::tick.
 * Зависимости: Composer autoload, Support\Config, Supabase/Queue/Ocr/Pipeline.
 */

require __DIR__ . '/../vendor/autoload.php';

use ChekiPrices\Worker\Ocr\OcrServiceClient;
use ChekiPrices\Worker\Pipeline\ReceiptProcessor;
use ChekiPrices\Worker\Pipeline\Steps\OcrFallbackStep;
use ChekiPrices\Worker\Pipeline\Steps\PersistReceiptStep;
use ChekiPrices\Worker\Queue\JobConsumer;
use ChekiPrices\Worker\Queue\PgmqClient;
use ChekiPrices\Worker\Supabase\ReceiptRepository;
use ChekiPrices\Worker\Supabase\SupabaseClient;
use ChekiPrices\Worker\Support\Config;
use ChekiPrices\Worker\Support\Logger;

if (is_file(__DIR__ . '/../.env')) {
    Dotenv\Dotenv::createImmutable(__DIR__ . '/..')->load();
}

$cfg = new Config();
$log = new Logger();
$http = new GuzzleHttp\Client(['timeout' => 60]);

$supabase = new SupabaseClient($cfg->require('SUPABASE_URL'), $cfg->require('SUPABASE_SERVICE_ROLE_KEY'), $http);
$repo = new ReceiptRepository($supabase);
$ocrClient = new OcrServiceClient($cfg->require('OCR_SERVICE_URL'), $http);
$ocrStep = new OcrFallbackStep($ocrClient, $supabase, $cfg->get('RECEIPTS_BUCKET', 'receipts'));
$persist = new PersistReceiptStep($repo);
$processor = new ReceiptProcessor($ocrStep, $persist, $repo);

$queue = new PgmqClient($supabase);
$consumer = new JobConsumer($queue, $processor, $repo, $cfg->get('QUEUE_NAME', 'receipts_processing'), $cfg->int('QUEUE_MAX_ATTEMPTS', 5));

$vt = $cfg->int('QUEUE_VISIBILITY_TIMEOUT', 60);
$batch = $cfg->int('QUEUE_BATCH', 5);
$sleep = $cfg->int('WORKER_SLEEP_SECONDS', 5);

$log->info('worker started');
while (true) {
    try {
        $consumer->tick($vt, $batch);
    } catch (\Throwable $e) {
        $log->error('tick failed: ' . $e->getMessage());
    }
    sleep($sleep);
}
```

> Если сигнатура `Logger::info/error` отличается — подстрой вызовы под фактический
> `Support/Logger.php` (прочитай его). Если методов нет — добавь тонкую обёртку над
> monolog в Logger в рамках этой задачи.

- [ ] **Step 4: Commit**

```bash
git add worker/src/Queue/JobConsumer.php worker/bin/worker.php worker/tests/Queue/JobConsumerTest.php
git commit -m "feat(worker): job consumer loop with retry/archive and entrypoint wiring"
```

---

### Task 9: CI — убедиться, что worker-тесты гоняются; php-worker-reviewer; docs

**Files:**
- Modify (при необходимости): `.github/workflows/ci.yml`
- Modify: `docs/features/scan.md`, `docs/architecture/data-flow.md`

- [ ] **Step 1: Проверить CI job `worker`**

Прочитать `.github/workflows/ci.yml`. Убедиться, что job `worker` ставит зависимости (`composer install`), запускает `php -l` и `phpunit` (через `composer test`). Если шага тестов нет — добавить `- run: composer test` (working-directory: worker). Проверить YAML: `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))"`.

- [ ] **Step 2: Запустить субагент `php-worker-reviewer`**

Дать на ревью весь diff воркера (Tasks 2–8): провайдер-паттерн не нарушен, очередь (delete/retry/archive) корректна, доступ к БД только service-role, PSR-12/типизация, PHPDoc-шапки, отсутствие проглоченных ошибок (исключения доходят до статуса failed). Исправить замечания.

- [ ] **Step 3: Обновить docs**

`docs/features/scan.md`: в разделе про воркер заменить «Прямого нет … воркер его не читает» на актуальное: воркер читает pgmq, скачивает фото, вызывает OCR-сервис, пишет позиции с confidence и ставит `review`; клиент подтверждает через `confirm_receipt`. `docs/architecture/data-flow.md` уже обновлён в плане №2 — сверить согласованность (OCR-сервис как основной путь).

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/ci.yml docs/features/scan.md docs/architecture/data-flow.md
git commit -m "ci+docs(worker): run worker tests; document server OCR worker path"
```

---

## Self-Review (выполнено при написании плана)

- **Spec coverage:** «Компонент 3 — Воркер (тонкий)» из спеки покрыт: OCR-шаг
  (Storage→сервис) — Task 5; запись `receipt_items`+confidence+статус — Tasks 6–7; pgmq
  read/delete/archive+retry — Tasks 4, 8; wiring — Task 8. confidence-колонка (gap
  плана №2) — Task 1. Нормализация/публикация цен — вне объёма (отмечено).
- **Placeholder scan:** плейсхолдеров нет; код во всех шагах. Две явные врезки требуют
  действия исполнителя (user_id в receipt_items под service-role — Task 6; сверка
  сигнатуры Logger — Task 8) — это конкретные инструкции, не TODO.
- **Type/имя consistency:** `ReceiptRepository::getReceiptContext(): array{user_id,
  family_id,photo_path}`, `replaceItems(receiptId,userId,familyId,items)`,
  `markReview(receiptId,?total)`, `markFailed(receiptId,error)` — согласованы между
  Tasks 6, 7, 8. `JobConsumer(__construct: queue, processor, receipts, queueName,
  maxAttempts)` и `tick(vt,batch)` — согласованы между Task 8 и тестами.
  `ReceiptProcessor(ocr, persist, receipts)` — Task 7 ↔ тесты.

## Известные риски (для исполнителя)

- **PHP локально не запускается** — все PHPUnit-тесты верифицируются ТОЛЬКО в CI.
  Локальные гейты: `php-worker-reviewer` (Task 9) + статический разбор кода.
- **user_id под service-role:** триггер `receipt_items_fill_owner` ставит `auth.uid()`
  (= null под service-role) → воркер обязан проставлять `user_id`/`family_id` сам из
  чека (Task 6 врезка). Не игнорировать.
- **Storage download path:** эндпоинт Supabase Storage для приватного объекта под
  service-role — `/storage/v1/object/{bucket}/{path}`. Если на проекте включён иной путь
  (`/authenticated/`), скорректировать в Task 3 (проверяется в CI/деплое, не локально).
- **read_ct семантика pgmq:** ретрай завязан на `read_ct` сообщения. Граница
  `read_ct >= maxAttempts` означает «исчерпано» — сверить инклюзивность на реальной pgmq
  в деплое.
