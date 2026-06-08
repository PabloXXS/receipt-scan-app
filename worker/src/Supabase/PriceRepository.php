<?php

declare(strict_types=1);

/**
 * Назначение: запись обезличенных цен и агрегатов (зона C).
 *
 * Роль в пайплайне: используется PublishPricesStep.
 * Зависимости: SupabaseClient.
 */

namespace ChekiPrices\Worker\Supabase;

/**
 * Репозиторий карты цен (зона C, без user_id/family_id).
 */
final class PriceRepository
{
    public function __construct(
        private readonly SupabaseClient $client,
    ) {
    }

    /**
     * Вставляет обезличенные наблюдения цен.
     *
     * @param list<array<string, mixed>> $observations
     * @throws \RuntimeException пока не реализовано.
     */
    public function insertObservations(array $observations): void
    {
        throw new \RuntimeException('Not implemented');
    }
}
