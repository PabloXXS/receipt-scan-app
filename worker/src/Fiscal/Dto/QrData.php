<?php

declare(strict_types=1);

/**
 * Назначение: DTO разобранных данных QR-кода чека.
 *
 * Роль в пайплайне: вход для FiscalProviderInterface::fetchReceipt.
 * Зависимости: нет.
 */

namespace ChekiPrices\Worker\Fiscal\Dto;

/**
 * Сырые данные QR кассового чека.
 */
final readonly class QrData
{
    public function __construct(
        public string $raw,
        public string $countryCode,
    ) {
    }
}
