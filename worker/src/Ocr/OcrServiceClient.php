<?php

declare(strict_types=1);

/**
 * Назначение: HTTP-клиент OCR-сервиса (фото → распознанные позиции).
 *
 * Роль в пайплайне: используется OcrFallbackStep; превращает ответ OCR-сервиса
 * (план №1) в ReceiptData.
 * Зависимости: guzzlehttp/guzzle, Fiscal\Dto\{ReceiptData,ItemData}.
 */

namespace ChekiPrices\Worker\Ocr;

use ChekiPrices\Worker\Fiscal\Dto\ItemData;
use ChekiPrices\Worker\Fiscal\Dto\ReceiptData;
use GuzzleHttp\ClientInterface;

/**
 * Клиент OCR-сервиса: шлёт байты фото и парсит ответ в ReceiptData.
 */
class OcrServiceClient
{
    public function __construct(
        private readonly string $baseUrl,
        private readonly ClientInterface $http,
    ) {
    }

    /** Распознаёт позиции по байтам фото через OCR-сервис. */
    public function recognize(string $photoBytes): ReceiptData
    {
        $resp = $this->http->request('POST', rtrim($this->baseUrl, '/') . '/ocr', [
            'multipart' => [[
                'name' => 'photo',
                'contents' => $photoBytes,
                'filename' => 'receipt.jpg',
                'headers' => ['Content-Type' => 'image/jpeg'],
            ]],
        ]);
        /** @var array{items:list<array<string,mixed>>,total?:float|null,confidence?:float} $data */
        $data = json_decode((string) $resp->getBody(), true, 512, JSON_THROW_ON_ERROR);

        $items = [];
        foreach ($data['items'] as $it) {
            $items[] = new ItemData(
                rawName: (string) $it['raw_name'],
                qty: (float) ($it['qty'] ?? 1),
                unitPrice: (float) ($it['unit_price'] ?? 0),
                sum: (float) ($it['sum'] ?? 0),
                confidence: isset($it['confidence']) ? (float) $it['confidence'] : null,
                barcode: isset($it['barcode']) && $it['barcode'] !== null ? (string) $it['barcode'] : null,
            );
        }

        return new ReceiptData(
            storeExternalId: null,
            purchasedAt: null,
            total: isset($data['total']) ? (float) $data['total'] : null,
            currency: null,
            items: $items,
        );
    }
}
