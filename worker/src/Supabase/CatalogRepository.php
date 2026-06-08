<?php

declare(strict_types=1);

/**
 * Назначение: доступ к справочнику products/aliases/stores/chains.
 *
 * Роль в пайплайне: используется нормализацией и привязкой магазина.
 * Зависимости: SupabaseClient.
 */

namespace ChekiPrices\Worker\Supabase;

/**
 * Репозиторий общего справочника (зона B).
 */
final class CatalogRepository
{
    public function __construct(
        private readonly SupabaseClient $client,
    ) {
    }

    /**
     * Ищет product_id по сырому названию и стране.
     *
     * @throws \RuntimeException пока не реализовано.
     */
    public function findProductIdByAlias(string $rawName, string $countryCode): ?string
    {
        throw new \RuntimeException('Not implemented');
    }
}
