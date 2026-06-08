<?php

declare(strict_types=1);

/**
 * Назначение: фискальный провайдер для России (ФНС).
 *
 * Роль в пайплайне: реализация FiscalProviderInterface для country_code = RU.
 * Зависимости: FiscalProviderInterface, Dto\*.
 * Заглушка: интеграция с API ФНС — в отдельной итерации.
 */

namespace ChekiPrices\Worker\Fiscal\Providers;

use ChekiPrices\Worker\Fiscal\Dto\QrData;
use ChekiPrices\Worker\Fiscal\Dto\ReceiptData;
use ChekiPrices\Worker\Fiscal\FiscalProviderInterface;

/**
 * Провайдер ФНС РФ.
 */
final class RuFnsProvider implements FiscalProviderInterface
{
    public function fetchReceipt(QrData $qr): ReceiptData
    {
        throw new \RuntimeException('Not implemented');
    }
}
