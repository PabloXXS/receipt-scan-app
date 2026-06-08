<?php

declare(strict_types=1);

/**
 * Назначение: контракт фискального провайдера (страна → стратегия).
 *
 * Роль в пайплайне: абстракция получения состава чека по QR.
 * Зависимости: Dto\QrData, Dto\ReceiptData.
 */

namespace ChekiPrices\Worker\Fiscal;

use ChekiPrices\Worker\Fiscal\Dto\QrData;
use ChekiPrices\Worker\Fiscal\Dto\ReceiptData;

/**
 * Стратегия получения состава чека у фискального оператора страны.
 */
interface FiscalProviderInterface
{
    /**
     * Запрашивает состав чека по данным QR.
     */
    public function fetchReceipt(QrData $qr): ReceiptData;
}
