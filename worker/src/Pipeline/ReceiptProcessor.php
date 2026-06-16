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
class ReceiptProcessor
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
        // receipts.user_id NOT NULL — в норме owner есть. Но задача может
        // ссылаться на удалённый чек: контекст пуст, user_id придёт null.
        // Без owner запись receipt_items под service-role нарушит NOT NULL и
        // разорвёт привязку к владельцу — это перманентный отказ, ретрай
        // бессмыслен, ведём себя как при отсутствии photo_path.
        $userId = $ctx['user_id'] ?? null;
        if ($userId === null || $userId === '') {
            $this->receipts->markFailed($receiptId, 'no user_id for receipt');
            return new ProcessingResult('failed', 'no user_id');
        }
        $data = $this->ocr->run($photoPath);
        $this->persist->run($receiptId, $userId, $ctx['family_id'], $data);
        return new ProcessingResult('review');
    }
}
