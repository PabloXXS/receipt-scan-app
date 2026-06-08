<?php

declare(strict_types=1);

/**
 * Назначение: DTO полного состава чека от провайдера/OCR.
 *
 * Роль в пайплайне: результат FetchFiscalDataStep/OcrFallbackStep; вход
 * нормализации, записи и анонимизации.
 * Зависимости: Dto\ItemData.
 */

namespace ChekiPrices\Worker\Fiscal\Dto;

/**
 * Состав чека: магазин, дата, итог и позиции.
 */
final readonly class ReceiptData
{
    /**
     * @param list<ItemData> $items
     */
    public function __construct(
        public ?string $storeExternalId,
        public ?string $purchasedAt,
        public ?float $total,
        public ?string $currency,
        public array $items,
    ) {
    }
}
