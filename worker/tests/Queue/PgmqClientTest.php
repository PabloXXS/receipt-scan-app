<?php

declare(strict_types=1);

namespace ChekiPrices\Worker\Tests\Queue;

use ChekiPrices\Worker\Queue\PgmqClient;
use ChekiPrices\Worker\Supabase\SupabaseClient;
use PHPUnit\Framework\TestCase;

final class PgmqClientTest extends TestCase
{
    public function testReadMapsRpcRows(): void
    {
        $supabase = $this->createMock(SupabaseClient::class);
        $supabase->expects(self::once())->method('rpc')
            ->with('pgmq_read_jobs', ['p_queue' => 'q', 'p_vt' => 30, 'p_qty' => 2])
            ->willReturn([
                ['msg_id' => 7, 'read_ct' => 1, 'message' => ['receipt_id' => 'r1']],
            ]);

        $jobs = (new PgmqClient($supabase))->read('q', 30, 2);

        self::assertCount(1, $jobs);
        self::assertSame(7, $jobs[0]['msg_id']);
        self::assertSame(1, $jobs[0]['read_ct']);
        self::assertSame('r1', $jobs[0]['message']['receipt_id']);
    }

    public function testDeleteAndArchiveCallRpc(): void
    {
        $supabase = $this->createMock(SupabaseClient::class);
        $supabase->expects(self::exactly(2))->method('rpc')
            ->willReturnCallback(function (string $fn, array $args): array {
                self::assertContains($fn, ['pgmq_delete_job', 'pgmq_archive_job']);
                self::assertSame(['p_queue' => 'q', 'p_msg_id' => 7], $args);
                return [];
            });

        $c = new PgmqClient($supabase);
        $c->delete('q', 7);
        $c->archive('q', 7);
    }
}
