<?php

declare(strict_types=1);

namespace ChekiPrices\Worker\Tests\Fiscal\Dto;

use ChekiPrices\Worker\Fiscal\Dto\ItemData;
use PHPUnit\Framework\TestCase;

final class ItemDataTest extends TestCase
{
    public function testHoldsConfidenceAndBarcode(): void
    {
        $i = new ItemData('Молоко', 1.0, 2.5, 2.5, 0.92, '4811');
        self::assertSame('Молоко', $i->rawName);
        self::assertSame(0.92, $i->confidence);
        self::assertSame('4811', $i->barcode);
    }

    public function testConfidenceAndBarcodeNullable(): void
    {
        $i = new ItemData('X', 1.0, 1.0, 1.0);
        self::assertNull($i->confidence);
        self::assertNull($i->barcode);
    }
}
