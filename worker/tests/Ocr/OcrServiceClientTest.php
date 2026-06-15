<?php

declare(strict_types=1);

namespace ChekiPrices\Worker\Tests\Ocr;

use ChekiPrices\Worker\Ocr\OcrServiceClient;
use GuzzleHttp\Client;
use GuzzleHttp\Handler\MockHandler;
use GuzzleHttp\HandlerStack;
use GuzzleHttp\Psr7\Response;
use PHPUnit\Framework\TestCase;

final class OcrServiceClientTest extends TestCase
{
    public function testParsesItemsIntoReceiptData(): void
    {
        $json = json_encode([
            'items' => [
                ['raw_name' => 'Молоко', 'qty' => 1, 'unit_price' => 2.5, 'sum' => 2.5,
                 'confidence' => 0.9, 'barcode' => '4811'],
                ['raw_name' => 'Хлеб', 'qty' => 2, 'unit_price' => 1.25, 'sum' => 2.5,
                 'confidence' => 0.8, 'barcode' => null],
            ],
            'total' => 5.0,
            'confidence' => 0.85,
        ]);
        $http = new Client(['handler' => HandlerStack::create(new MockHandler([new Response(200, [], $json)]))]);

        $receipt = (new OcrServiceClient('http://ocr:8000', $http))->recognize("\xFF\xD8jpeg");

        self::assertSame(5.0, $receipt->total);
        self::assertCount(2, $receipt->items);
        self::assertSame('Молоко', $receipt->items[0]->rawName);
        self::assertSame(0.9, $receipt->items[0]->confidence);
        self::assertSame(2.0, $receipt->items[1]->qty);
    }
}
