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

/**
 * Скачивает фото чека из Storage и распознаёт позиции через OCR-сервис.
 */
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
