<?php

declare(strict_types=1);

/**
 * Назначение: шаг — OCR-fallback, если фискальные данные не получены.
 *
 * Роль в пайплайне: шаг 2 (условный) ReceiptProcessor.
 * Зависимости: Ocr\ReceiptOcrParser, Fiscal\Dto\ReceiptData.
 */

namespace ChekiPrices\Worker\Pipeline\Steps;

use ChekiPrices\Worker\Fiscal\Dto\ReceiptData;
use ChekiPrices\Worker\Ocr\ReceiptOcrParser;

/**
 * OCR-распознавание чека по фото как запасной путь.
 */
final class OcrFallbackStep
{
    public function __construct(
        private readonly ReceiptOcrParser $parser,
    ) {
    }

    /**
     * @throws \RuntimeException пока не реализовано.
     */
    public function run(string $photoPath): ReceiptData
    {
        throw new \RuntimeException('Not implemented');
    }
}
