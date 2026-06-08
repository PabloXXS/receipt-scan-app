<?php

declare(strict_types=1);

/**
 * Назначение: оркестратор шагов обработки одного чека.
 *
 * Роль в пайплайне: вызывается JobConsumer; последовательно прогоняет шаги
 * Fetch → (Ocr fallback) → Normalize → Persist → PublishPrices.
 * Зависимости: Pipeline\Steps\*, Pipeline\ProcessingResult.
 */

namespace ChekiPrices\Worker\Pipeline;

use ChekiPrices\Worker\Pipeline\Steps\FetchFiscalDataStep;
use ChekiPrices\Worker\Pipeline\Steps\NormalizeItemsStep;
use ChekiPrices\Worker\Pipeline\Steps\OcrFallbackStep;
use ChekiPrices\Worker\Pipeline\Steps\PersistReceiptStep;
use ChekiPrices\Worker\Pipeline\Steps\PublishPricesStep;

/**
 * Оркестратор обработки чека.
 */
final class ReceiptProcessor
{
    public function __construct(
        private readonly FetchFiscalDataStep $fetch,
        private readonly OcrFallbackStep $ocrFallback,
        private readonly NormalizeItemsStep $normalize,
        private readonly PersistReceiptStep $persist,
        private readonly PublishPricesStep $publishPrices,
    ) {
    }

    /**
     * Обрабатывает чек по его идентификатору.
     *
     * @throws \RuntimeException пока не реализовано.
     */
    public function process(string $receiptId): ProcessingResult
    {
        throw new \RuntimeException('Not implemented');
    }
}
