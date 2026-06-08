<?php

declare(strict_types=1);

/**
 * Назначение: фискальный провайдер для Казахстана.
 *
 * Роль в пайплайне: реализация FiscalProviderInterface для country_code = KZ.
 * Зависимости: FiscalProviderInterface, Dto\*.
 * Заглушка: интеграция — в отдельной итерации.
 */

namespace ChekiPrices\Worker\Fiscal\Providers;

use ChekiPrices\Worker\Fiscal\Dto\QrData;
use ChekiPrices\Worker\Fiscal\Dto\ReceiptData;
use ChekiPrices\Worker\Fiscal\FiscalProviderInterface;

/**
 * Провайдер для Казахстана.
 */
final class KzProvider implements FiscalProviderInterface
{
    public function fetchReceipt(QrData $qr): ReceiptData
    {
        throw new \RuntimeException('Not implemented');
    }
}
