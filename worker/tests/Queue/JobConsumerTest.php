<?php

declare(strict_types=1);

namespace ChekiPrices\Worker\Tests\Queue;

use ChekiPrices\Worker\Pipeline\ProcessingResult;
use ChekiPrices\Worker\Pipeline\ReceiptProcessor;
use ChekiPrices\Worker\Queue\JobConsumer;
use ChekiPrices\Worker\Queue\PgmqClient;
use ChekiPrices\Worker\Supabase\ReceiptRepository;
use PHPUnit\Framework\TestCase;

final class JobConsumerTest extends TestCase
{
    public function testDeletesMessageOnSuccess(): void
    {
        $queue = $this->createMock(PgmqClient::class);
        $queue->method('read')->willReturn([
            ['msg_id' => 7, 'read_ct' => 1, 'message' => ['receipt_id' => 'r1']],
        ]);
        $queue->expects(self::once())->method('delete')->with('q', 7);

        $processor = $this->createMock(ReceiptProcessor::class);
        $processor->method('process')->with('r1')->willReturn(new ProcessingResult('review'));

        $repo = $this->createMock(ReceiptRepository::class);

        (new JobConsumer($queue, $processor, $repo, 'q', 5))->tick(30, 5);
    }

    public function testDeletesWhenProcessReturnsFailedWithoutException(): void
    {
        // Перманентный отказ (например, нет photo_path): process() сам зовёт
        // markFailed и возвращает ProcessingResult('failed', ...) БЕЗ исключения.
        // Консьюмер трактует это как «задача завершена» → delete; archive и
        // markFailed консьюмером НЕ вызываются (их уже сделал процессор).
        $queue = $this->createMock(PgmqClient::class);
        $queue->method('read')->willReturn([
            ['msg_id' => 7, 'read_ct' => 1, 'message' => ['receipt_id' => 'r1']],
        ]);
        $queue->expects(self::once())->method('delete')->with('q', 7);
        $queue->expects(self::never())->method('archive');

        $processor = $this->createMock(ReceiptProcessor::class);
        $processor->method('process')->with('r1')
            ->willReturn(new ProcessingResult('failed', 'no photo'));

        $repo = $this->createMock(ReceiptRepository::class);
        $repo->expects(self::never())->method('markFailed');

        (new JobConsumer($queue, $processor, $repo, 'q', 5))->tick(30, 5);
    }

    public function testArchivesAndFailsAfterMaxAttempts(): void
    {
        $queue = $this->createMock(PgmqClient::class);
        $queue->method('read')->willReturn([
            ['msg_id' => 7, 'read_ct' => 5, 'message' => ['receipt_id' => 'r1']],
        ]);
        $queue->expects(self::once())->method('archive')->with('q', 7);
        $queue->expects(self::never())->method('delete');

        $processor = $this->createMock(ReceiptProcessor::class);
        $processor->method('process')->willThrowException(new \RuntimeException('boom'));

        $repo = $this->createMock(ReceiptRepository::class);
        $repo->expects(self::once())->method('markFailed')->with('r1', self::stringContains('boom'));

        (new JobConsumer($queue, $processor, $repo, 'q', 5))->tick(30, 5);
    }

    public function testLeavesMessageForRetryBeforeMaxAttempts(): void
    {
        $queue = $this->createMock(PgmqClient::class);
        $queue->method('read')->willReturn([
            ['msg_id' => 7, 'read_ct' => 2, 'message' => ['receipt_id' => 'r1']],
        ]);
        $queue->expects(self::never())->method('archive');
        $queue->expects(self::never())->method('delete');

        $processor = $this->createMock(ReceiptProcessor::class);
        $processor->method('process')->willThrowException(new \RuntimeException('temp'));

        $repo = $this->createMock(ReceiptRepository::class);
        $repo->expects(self::never())->method('markFailed');

        (new JobConsumer($queue, $processor, $repo, 'q', 5))->tick(30, 5);
    }
}
