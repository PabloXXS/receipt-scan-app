<?php

declare(strict_types=1);

/**
 * Назначение: шаг — записать receipt_items и обновить статус чека.
 *
 * Роль в пайплайне: шаг 4 ReceiptProcessor.
 * Зависимости: Supabase\ReceiptRepository, Fiscal\Dto\ReceiptData.
 */

namespace ChekiPrices\Worker\Pipeline\Steps;

use ChekiPrices\Worker\Fiscal\Dto\ReceiptData;
use ChekiPrices\Worker\Supabase\ReceiptRepository;

/**
 * Сохранение позиций чека и финального статуса.
 */
final class PersistReceiptStep
{
    public function __construct(
        private readonly ReceiptRepository $receipts,
    ) {
    }

    /**
     * @throws \RuntimeException пока не реализовано.
     */
    public function run(string $receiptId, ReceiptData $receipt): void
    {
        throw new \RuntimeException('Not implemented');
    }
}
