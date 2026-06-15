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

/**
 * Сохранение позиций чека и перевод чека в статус review.
 */
final class PersistReceiptStep
{
    public function __construct(private readonly ReceiptRepository $receipts)
    {
    }

    /** Сохраняет позиции и ставит статус review с итогом (печатный или сумма позиций). */
    public function run(string $receiptId, string $userId, ?string $familyId, ReceiptData $receipt): void
    {
        $this->receipts->replaceItems($receiptId, $userId, $familyId, $receipt->items);
        $total = $receipt->total ?? $this->sumItems($receipt);
        $this->receipts->markReview($receiptId, $total);
    }

    /** Сумма позиций как запасной итог, если печатный total отсутствует. */
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
