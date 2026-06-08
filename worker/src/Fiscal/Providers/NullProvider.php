<?php

declare(strict_types=1);

/**
 * Назначение: провайдер-заглушка для стран без интеграции (всегда триггерит OCR-fallback).
 *
 * Роль в пайплайне: безопасный дефолт фабрики; форсирует OcrFallbackStep.
 * Зависимости: FiscalProviderInterface, Dto\*.
 */

namespace ChekiPrices\Worker\Fiscal\Providers;

use ChekiPrices\Worker\Fiscal\Dto\QrData;
use ChekiPrices\Worker\Fiscal\Dto\ReceiptData;
use ChekiPrices\Worker\Fiscal\FiscalProviderInterface;

/**
 * Провайдер по умолчанию: фискальные данные недоступны.
 */
final class NullProvider implements FiscalProviderInterface
{
    /**
     * Всегда возвращает пустой состав (сигнал к OCR-fallback).
     */
    public function fetchReceipt(QrData $qr): ReceiptData
    {
        return new ReceiptData(null, null, null, null, []);
    }
}
