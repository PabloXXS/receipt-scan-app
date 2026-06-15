<?php

declare(strict_types=1);

namespace ChekiPrices\Worker\Tests\Pipeline;

use ChekiPrices\Worker\Fiscal\Dto\ItemData;
use ChekiPrices\Worker\Fiscal\Dto\ReceiptData;
use ChekiPrices\Worker\Pipeline\ReceiptProcessor;
use ChekiPrices\Worker\Pipeline\Steps\OcrFallbackStep;
use ChekiPrices\Worker\Pipeline\Steps\PersistReceiptStep;
use ChekiPrices\Worker\Supabase\ReceiptRepository;
use PHPUnit\Framework\TestCase;

final class ReceiptProcessorTest extends TestCase
{
    public function testProcessesReceiptToReview(): void
    {
        $repo = $this->createMock(ReceiptRepository::class);
        $repo->method('getReceiptContext')->with('r1')
            ->willReturn(['user_id' => 'u1', 'family_id' => null, 'photo_path' => 'uid/ts.jpg']);

        $receipt = new ReceiptData(null, null, 5.0, null, [new ItemData('A', 1, 5.0, 5.0)]);
        $ocr = $this->createMock(OcrFallbackStep::class);
        $ocr->method('run')->with('uid/ts.jpg')->willReturn($receipt);

        $persist = $this->createMock(PersistReceiptStep::class);
        $persist->expects(self::once())->method('run')->with('r1', 'u1', null, $receipt);

        $result = (new ReceiptProcessor($ocr, $persist, $repo))->process('r1');
        self::assertSame('review', $result->status);
    }

    public function testMissingPhotoMarksFailed(): void
    {
        $repo = $this->createMock(ReceiptRepository::class);
        $repo->method('getReceiptContext')->willReturn(['user_id' => 'u1', 'family_id' => null, 'photo_path' => null]);
        $repo->expects(self::once())->method('markFailed')->with('r1', self::stringContains('photo'));

        $ocr = $this->createMock(OcrFallbackStep::class);
        $persist = $this->createMock(PersistReceiptStep::class);

        $result = (new ReceiptProcessor($ocr, $persist, $repo))->process('r1');
        self::assertSame('failed', $result->status);
    }
}
