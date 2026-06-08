<?php

declare(strict_types=1);

/**
 * Назначение: шаг — выбрать провайдера по стране и запросить состав чека.
 *
 * Роль в пайплайне: шаг 1 ReceiptProcessor.
 * Зависимости: Fiscal\FiscalProviderFactory, Fiscal\Dto\*.
 */

namespace ChekiPrices\Worker\Pipeline\Steps;

use ChekiPrices\Worker\Fiscal\Dto\QrData;
use ChekiPrices\Worker\Fiscal\Dto\ReceiptData;
use ChekiPrices\Worker\Fiscal\FiscalProviderFactory;

/**
 * Получение фискальных данных чека.
 */
final class FetchFiscalDataStep
{
    public function __construct(
        private readonly FiscalProviderFactory $factory,
    ) {
    }

    /**
     * @throws \RuntimeException пока не реализовано.
     */
    public function run(QrData $qr): ReceiptData
    {
        throw new \RuntimeException('Not implemented');
    }
}
