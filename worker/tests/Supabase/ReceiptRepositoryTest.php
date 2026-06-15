<?php

declare(strict_types=1);

namespace ChekiPrices\Worker\Tests\Supabase;

use ChekiPrices\Worker\Fiscal\Dto\ItemData;
use ChekiPrices\Worker\Supabase\ReceiptRepository;
use ChekiPrices\Worker\Supabase\SupabaseClient;
use PHPUnit\Framework\TestCase;

final class ReceiptRepositoryTest extends TestCase
{
    public function testGetReceiptContextReturnsOwnerAndPhoto(): void
    {
        $supabase = $this->createMock(SupabaseClient::class);
        $supabase->method('request')->willReturn([
            ['user_id' => 'u1', 'family_id' => null, 'photo_path' => 'uid/ts.jpg'],
        ]);

        $ctx = (new ReceiptRepository($supabase))->getReceiptContext('r1');

        self::assertSame('u1', $ctx['user_id']);
        self::assertNull($ctx['family_id']);
        self::assertSame('uid/ts.jpg', $ctx['photo_path']);
    }

    public function testGetReceiptContextNullsWhenMissing(): void
    {
        $supabase = $this->createMock(SupabaseClient::class);
        $supabase->method('request')->willReturn([]);

        $ctx = (new ReceiptRepository($supabase))->getReceiptContext('r1');

        self::assertNull($ctx['user_id']);
        self::assertNull($ctx['family_id']);
        self::assertNull($ctx['photo_path']);
    }

    public function testReplaceItemsDeletesThenInsertsWithOwner(): void
    {
        $items = [new ItemData('Молоко', 1.0, 2.5, 2.5, 0.9, '4811')];

        $supabase = $this->createMock(SupabaseClient::class);
        $calls = [];
        $supabase->expects(self::exactly(2))->method('request')
            ->willReturnCallback(function (string $method, string $path, array $opts) use (&$calls): array {
                $calls[] = [$method, $path, $opts];
                return [];
            });

        (new ReceiptRepository($supabase))->replaceItems('r1', 'u1', null, $items);

        self::assertSame('DELETE', $calls[0][0]);
        self::assertSame('receipt_items', $calls[0][1]);
        self::assertSame('POST', $calls[1][0]);
        self::assertSame('receipt_items', $calls[1][1]);
        $row = $calls[1][2]['json'][0];
        self::assertSame('r1', $row['receipt_id']);
        self::assertSame('u1', $row['user_id']);
        self::assertNull($row['family_id']);
        self::assertSame('Молоко', $row['raw_name']);
        self::assertSame(0.9, $row['confidence']);
    }

    public function testReplaceItemsSkipsInsertWhenEmpty(): void
    {
        $supabase = $this->createMock(SupabaseClient::class);
        $supabase->expects(self::once())->method('request')
            ->with('DELETE', 'receipt_items', self::anything())
            ->willReturn([]);

        (new ReceiptRepository($supabase))->replaceItems('r1', 'u1', null, []);
    }

    public function testMarkReviewPatchesStatusAndTotal(): void
    {
        $supabase = $this->createMock(SupabaseClient::class);
        $supabase->expects(self::once())->method('request')
            ->with('PATCH', self::stringContains('receipts?id=eq.r1'), self::callback(
                static fn (array $opts): bool => $opts['json'] === ['status' => 'review', 'total' => 5.0],
            ))->willReturn([]);

        (new ReceiptRepository($supabase))->markReview('r1', 5.0);
    }

    public function testMarkFailedPatchesStatusAndError(): void
    {
        $supabase = $this->createMock(SupabaseClient::class);
        $supabase->expects(self::once())->method('request')
            ->with('PATCH', self::stringContains('receipts?id=eq.r1'), self::callback(
                static fn (array $opts): bool => $opts['json'] === ['status' => 'failed', 'error' => 'boom'],
            ))->willReturn([]);

        (new ReceiptRepository($supabase))->markFailed('r1', 'boom');
    }
}
