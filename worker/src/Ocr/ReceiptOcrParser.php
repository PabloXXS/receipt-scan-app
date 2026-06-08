<?php

declare(strict_types=1);

/**
 * Назначение: разбор распознанного текста чека в ReceiptData.
 *
 * Роль в пайплайне: преобразует выход OcrEngineInterface в структуру чека.
 * Зависимости: OcrEngineInterface, Fiscal\Dto\ReceiptData.
 */

namespace ChekiPrices\Worker\Ocr;

use ChekiPrices\Worker\Fiscal\Dto\ReceiptData;

/**
 * Парсер текста чека в структурированные данные.
 */
final class ReceiptOcrParser
{
    public function __construct(
        private readonly OcrEngineInterface $engine,
    ) {
    }

    /**
     * Распознаёт и парсит фото чека в ReceiptData.
     *
     * @throws \RuntimeException пока не реализовано.
     */
    public function parse(string $photoPath): ReceiptData
    {
        throw new \RuntimeException('Not implemented');
    }
}
