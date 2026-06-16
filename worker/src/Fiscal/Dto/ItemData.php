<?php

declare(strict_types=1);

/**
 * Назначение: DTO одной позиции чека от фискального провайдера/OCR.
 *
 * Роль в пайплайне: элемент ReceiptData; вход для нормализации и записи.
 * Зависимости: нет.
 */

namespace ChekiPrices\Worker\Fiscal\Dto;

/**
 * Позиция чека (сырое название, количество, цена, уверенность OCR, штрихкод).
 */
final readonly class ItemData
{
    public function __construct(
        public string $rawName,
        public float $qty,
        public float $unitPrice,
        public float $sum,
        public ?float $confidence = null,
        public ?string $barcode = null,
    ) {
    }
}
