<?php

declare(strict_types=1);

/**
 * Назначение: шаг — опубликовать ОБЕЗЛИЧЕННЫЕ наблюдения цен.
 *
 * Роль в пайплайне: шаг 5 ReceiptProcessor; работает только с зоной C.
 * Зависимости: Privacy\PriceAnonymizer, Supabase\PriceRepository.
 */

namespace ChekiPrices\Worker\Pipeline\Steps;

use ChekiPrices\Worker\Fiscal\Dto\ReceiptData;
use ChekiPrices\Worker\Privacy\PriceAnonymizer;
use ChekiPrices\Worker\Supabase\PriceRepository;

/**
 * Публикация обезличенных цен в карту цен (зона C).
 */
final class PublishPricesStep
{
    public function __construct(
        private readonly PriceAnonymizer $anonymizer,
        private readonly PriceRepository $prices,
    ) {
    }

    /**
     * @throws \RuntimeException пока не реализовано.
     */
    public function run(ReceiptData $receipt, string $region): void
    {
        throw new \RuntimeException('Not implemented');
    }
}
