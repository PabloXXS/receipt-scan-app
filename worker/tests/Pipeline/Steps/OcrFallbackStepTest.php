<?php

declare(strict_types=1);

namespace ChekiPrices\Worker\Tests\Pipeline\Steps;

use ChekiPrices\Worker\Fiscal\Dto\ReceiptData;
use ChekiPrices\Worker\Ocr\OcrServiceClient;
use ChekiPrices\Worker\Pipeline\Steps\OcrFallbackStep;
use ChekiPrices\Worker\Supabase\SupabaseClient;
use PHPUnit\Framework\TestCase;

final class OcrFallbackStepTest extends TestCase
{
    public function testDownloadsPhotoAndCallsOcr(): void
    {
        $supabase = $this->createMock(SupabaseClient::class);
        $supabase->expects(self::once())->method('downloadObject')
            ->with('receipts', 'uid/ts.jpg')->willReturn("\xFF\xD8jpeg");

        $expected = new ReceiptData(null, null, 5.0, null, []);
        $ocr = $this->createMock(OcrServiceClient::class);
        $ocr->expects(self::once())->method('recognize')->with("\xFF\xD8jpeg")->willReturn($expected);

        $step = new OcrFallbackStep($ocr, $supabase, 'receipts');
        self::assertSame($expected, $step->run('uid/ts.jpg'));
    }
}
