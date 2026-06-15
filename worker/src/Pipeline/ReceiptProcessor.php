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

/**
 * Оркестратор обработки чека: распознавание позиций и перевод в review.
 */
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
