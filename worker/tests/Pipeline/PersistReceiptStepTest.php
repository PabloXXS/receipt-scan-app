<?php

declare(strict_types=1);

namespace ChekiPrices\Worker\Tests\Pipeline;

use ChekiPrices\Worker\Fiscal\Dto\ItemData;
use ChekiPrices\Worker\Fiscal\Dto\ReceiptData;
use ChekiPrices\Worker\Pipeline\Steps\PersistReceiptStep;
use ChekiPrices\Worker\Supabase\ReceiptRepository;
use PHPUnit\Framework\TestCase;

final class PersistReceiptStepTest extends TestCase
{
    public function testWritesItemsAndMarksReviewWithComputedTotal(): void
    {
        $items = [
            new ItemData('A', 1, 2.0, 2.0, 0.9),
            new ItemData('B', 1, 3.0, 3.0, 0.8),
        ];
        $receipt = new ReceiptData(null, null, null, null, $items); // total отсутствует → считаем сами

        $repo = $this->createMock(ReceiptRepository::class);
        $repo->expects(self::once())->method('replaceItems')
            ->with('r1', 'u1', null, $items);
        $repo->expects(self::once())->method('markReview')->with('r1', 5.0);

        (new PersistReceiptStep($repo))->run('r1', 'u1', null, $receipt);
    }

    public function testUsesPrintedTotalWhenPresent(): void
    {
        $items = [new ItemData('A', 1, 2.0, 2.0)];
        $receipt = new ReceiptData(null, null, 9.99, null, $items);
        $repo = $this->createMock(ReceiptRepository::class);
        $repo->method('replaceItems');
        $repo->expects(self::once())->method('markReview')->with('r1', 9.99);
        (new PersistReceiptStep($repo))->run('r1', 'u1', null, $receipt);
    }
}
