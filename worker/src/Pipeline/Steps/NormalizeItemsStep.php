<?php

declare(strict_types=1);

/**
 * Назначение: шаг — нормализовать сырые названия позиций в product_id.
 *
 * Роль в пайплайне: шаг 3 ReceiptProcessor.
 * Зависимости: Normalization\ProductNormalizer, Fiscal\Dto\ReceiptData.
 */

namespace ChekiPrices\Worker\Pipeline\Steps;

use ChekiPrices\Worker\Fiscal\Dto\ReceiptData;
use ChekiPrices\Worker\Normalization\ProductNormalizer;

/**
 * Нормализация позиций чека.
 */
final class NormalizeItemsStep
{
    public function __construct(
        private readonly ProductNormalizer $normalizer,
    ) {
    }

    /**
     * @throws \RuntimeException пока не реализовано.
     */
    public function run(ReceiptData $receipt, string $countryCode): ReceiptData
    {
        throw new \RuntimeException('Not implemented');
    }
}
