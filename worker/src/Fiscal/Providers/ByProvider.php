<?php

declare(strict_types=1);

/**
 * Назначение: фискальный провайдер для Беларуси.
 *
 * Роль в пайплайне: реализация FiscalProviderInterface для country_code = BY.
 * Зависимости: FiscalProviderInterface, Dto\*.
 * Заглушка: интеграция — в отдельной итерации.
 */

namespace ChekiPrices\Worker\Fiscal\Providers;

use ChekiPrices\Worker\Fiscal\Dto\QrData;
use ChekiPrices\Worker\Fiscal\Dto\ReceiptData;
use ChekiPrices\Worker\Fiscal\FiscalProviderInterface;

/**
 * Провайдер для Беларуси.
 */
final class ByProvider implements FiscalProviderInterface
{
    public function fetchReceipt(QrData $qr): ReceiptData
    {
        throw new \RuntimeException('Not implemented');
    }
}
