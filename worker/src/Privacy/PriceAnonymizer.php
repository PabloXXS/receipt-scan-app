<?php

declare(strict_types=1);

/**
 * Назначение: преобразует состав чека в обезличенные наблюдения цен.
 *
 * Роль в пайплайне: ЕДИНСТВЕННАЯ точка отрыва наблюдений от пользователя
 * (см. ../docs/architecture/privacy.md). Отбрасывает user_id/family_id.
 * Зависимости: Fiscal\Dto\ReceiptData.
 */

namespace ChekiPrices\Worker\Privacy;

use ChekiPrices\Worker\Fiscal\Dto\ReceiptData;

/**
 * Строит обезличенные наблюдения цен из обработанного чека.
 */
final class PriceAnonymizer
{
    /**
     * Возвращает наблюдения цен (product_id, store_id, region, price, currency,
     * observed_at) без user_id/family_id.
     *
     * @return list<array<string, mixed>>
     * @throws \RuntimeException пока не реализовано.
     */
    public function anonymize(ReceiptData $receipt, string $region): array
    {
        throw new \RuntimeException('Not implemented');
    }
}
