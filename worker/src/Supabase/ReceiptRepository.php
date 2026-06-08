<?php

declare(strict_types=1);

/**
 * Назначение: чтение receipts и запись receipt_items/статуса.
 *
 * Роль в пайплайне: используется PersistReceiptStep и JobConsumer.
 * Зависимости: SupabaseClient.
 */

namespace ChekiPrices\Worker\Supabase;

/**
 * Репозиторий чеков (зона A).
 */
final class ReceiptRepository
{
    public function __construct(
        private readonly SupabaseClient $client,
    ) {
    }

    /**
     * Помечает статус чека.
     *
     * @throws \RuntimeException пока не реализовано.
     */
    public function setStatus(string $receiptId, string $status, ?string $error = null): void
    {
        throw new \RuntimeException('Not implemented');
    }
}
