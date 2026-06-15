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
$log = new Logger($cfg->get('LOG_LEVEL', 'info') ?? 'info');
$http = new GuzzleHttp\Client(['timeout' => 60]);

$supabase = new SupabaseClient(
    $cfg->require('SUPABASE_URL'),
    $cfg->require('SUPABASE_SERVICE_ROLE_KEY'),
    $http,
);
$repo = new ReceiptRepository($supabase);
$ocrClient = new OcrServiceClient($cfg->require('OCR_SERVICE_URL'), $http);
$ocrStep = new OcrFallbackStep($ocrClient, $supabase, $cfg->get('RECEIPTS_BUCKET', 'receipts') ?? 'receipts');
$persist = new PersistReceiptStep($repo);
$processor = new ReceiptProcessor($ocrStep, $persist, $repo);

$queue = new PgmqClient($supabase);
$consumer = new JobConsumer(
    $queue,
    $processor,
    $repo,
    $cfg->get('QUEUE_NAME', 'receipts_processing') ?? 'receipts_processing',
    $cfg->int('QUEUE_MAX_ATTEMPTS', 5),
);

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
