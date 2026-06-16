<?php

declare(strict_types=1);

/**
 * Назначение: фискальный шаг (пока заглушён — фискального API в РБ нет).
 *
 * Роль в пайплайне: зарезервирован под будущий фискальный путь; сейчас возвращает
 * пустой ReceiptData (основной путь — OCR). ReceiptProcessor его не вызывает.
 * Зависимости: Fiscal\FiscalProviderFactory, Fiscal\Dto\*.
 */

namespace ChekiPrices\Worker\Pipeline\Steps;

use ChekiPrices\Worker\Fiscal\Dto\QrData;
use ChekiPrices\Worker\Fiscal\Dto\ReceiptData;
use ChekiPrices\Worker\Fiscal\FiscalProviderFactory;

/**
 * Получение фискальных данных чека (Null-путь до появления фискального API).
 */
final class FetchFiscalDataStep
{
    public function __construct(
        private readonly FiscalProviderFactory $factory,
    ) {
    }

    /** Пока возвращает пустой состав чека (фискального API нет). */
    public function run(QrData $qr): ReceiptData
    {
        return new ReceiptData(null, null, null, null, []);
    }
}
