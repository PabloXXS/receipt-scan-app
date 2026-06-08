<?php

declare(strict_types=1);

/**
 * Назначение: нормализация сырого названия позиции в канонический product_id.
 *
 * Роль в пайплайне: используется NormalizeItemsStep (через product_aliases/products).
 * Зависимости: Supabase\CatalogRepository (внедряется позже).
 */

namespace ChekiPrices\Worker\Normalization;

/**
 * Сопоставляет сырые названия товаров каноническому каталогу.
 */
final class ProductNormalizer
{
    /**
     * Возвращает product_id для сырого названия в контексте страны (или null).
     *
     * @throws \RuntimeException пока не реализовано.
     */
    public function resolveProductId(string $rawName, string $countryCode): ?string
    {
        throw new \RuntimeException('Not implemented');
    }
}
