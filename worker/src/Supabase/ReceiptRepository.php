<?php

declare(strict_types=1);

/**
 * Назначение: доступ воркера к receipts/receipt_items (service-role, PostgREST).
 *
 * Роль в пайплайне: чтение контекста чека (owner + photo_path), запись позиций
 * и статуса. Используется PersistReceiptStep, ReceiptProcessor и JobConsumer.
 * Зависимости: Supabase\SupabaseClient, Fiscal\Dto\ItemData.
 */

namespace ChekiPrices\Worker\Supabase;

use ChekiPrices\Worker\Fiscal\Dto\ItemData;

/**
 * Репозиторий чеков (зона A) поверх service-role PostgREST (минует RLS).
 */
final class ReceiptRepository
{
    public function __construct(
        private readonly SupabaseClient $client,
    ) {
    }

    /**
     * Контекст чека для обработки: владелец и путь фото.
     *
     * Триггер receipt_items_fill_owner ставит user_id := auth.uid(), но под
     * service-role это NULL при NOT NULL колонке — поэтому owner читаем здесь
     * и проставляем явно при записи позиций.
     *
     * @return array{user_id:?string, family_id:?string, photo_path:?string}
     */
    public function getReceiptContext(string $receiptId): array
    {
        $rows = $this->client->request('GET', 'receipts', [
            'query' => [
                'id' => 'eq.' . $receiptId,
                'select' => 'user_id,family_id,photo_path',
                'limit' => 1,
            ],
        ]);
        /** @var array<string,mixed> $row */
        $row = $rows[0] ?? [];
        return [
            'user_id' => isset($row['user_id']) && $row['user_id'] !== null ? (string) $row['user_id'] : null,
            'family_id' => isset($row['family_id']) && $row['family_id'] !== null ? (string) $row['family_id'] : null,
            'photo_path' => isset($row['photo_path']) && $row['photo_path'] !== null ? (string) $row['photo_path'] : null,
        ];
    }

    /**
     * Заменяет позиции чека (удаляет старые, вставляет новые).
     *
     * user_id/family_id проставляем явно: триггер receipt_items_fill_owner под
     * service-role получает auth.uid() = NULL, а колонка user_id — NOT NULL.
     *
     * @param list<ItemData> $items
     */
    public function replaceItems(string $receiptId, string $userId, ?string $familyId, array $items): void
    {
        $this->client->request('DELETE', 'receipt_items', [
            'query' => ['receipt_id' => 'eq.' . $receiptId],
        ]);
        if ($items === []) {
            return;
        }
        $rows = array_map(
            static fn (ItemData $i): array => [
                'receipt_id' => $receiptId,
                'user_id' => $userId,
                'family_id' => $familyId,
                'raw_name' => $i->rawName,
                'qty' => $i->qty,
                'unit_price' => $i->unitPrice,
                'sum' => $i->sum,
                'confidence' => $i->confidence,
            ],
            $items,
        );
        $this->client->request('POST', 'receipt_items', ['json' => $rows]);
    }

    /** Переводит чек в review с пересчитанным итогом. */
    public function markReview(string $receiptId, ?float $total): void
    {
        $this->client->request('PATCH', 'receipts?id=eq.' . $receiptId, [
            'json' => ['status' => 'review', 'total' => $total],
        ]);
    }

    /** Помечает чек как failed с текстом ошибки. */
    public function markFailed(string $receiptId, string $error): void
    {
        $this->client->request('PATCH', 'receipts?id=eq.' . $receiptId, [
            'json' => ['status' => 'failed', 'error' => $error],
        ]);
    }
}
