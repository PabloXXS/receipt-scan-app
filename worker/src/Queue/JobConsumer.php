<?php

declare(strict_types=1);

/**
 * Назначение: цикл обработки очереди — read → process → delete | retry/archive.
 *
 * Роль в пайплайне: верхнеуровневый драйвер; вызывает ReceiptProcessor.
 * Зависимости: PgmqClient, Pipeline\ReceiptProcessor, Supabase\ReceiptRepository.
 */

namespace ChekiPrices\Worker\Queue;

use ChekiPrices\Worker\Pipeline\ReceiptProcessor;
use ChekiPrices\Worker\Supabase\ReceiptRepository;

/**
 * Потребитель очереди pgmq: один проход цикла читает и обрабатывает задачи.
 */
final class JobConsumer
{
    public function __construct(
        private readonly PgmqClient $queue,
        private readonly ReceiptProcessor $processor,
        private readonly ReceiptRepository $receipts,
        private readonly string $queueName,
        private readonly int $maxAttempts,
    ) {
    }

    /**
     * Один проход: читает пачку и обрабатывает каждое сообщение.
     *
     * Успех → delete; исключение → если read_ct исчерпал maxAttempts, помечаем
     * чек failed и archive; иначе оставляем сообщение (vt вернёт его для ретрая).
     */
    public function tick(int $visibilityTimeout, int $batch): void
    {
        foreach ($this->queue->read($this->queueName, $visibilityTimeout, $batch) as $job) {
            $receiptId = (string) ($job['message']['receipt_id'] ?? '');
            try {
                if ($receiptId === '') {
                    throw new \RuntimeException('job without receipt_id');
                }
                $this->processor->process($receiptId);
                $this->queue->delete($this->queueName, $job['msg_id']);
            } catch (\Throwable $e) {
                if ($job['read_ct'] >= $this->maxAttempts) {
                    if ($receiptId !== '') {
                        $this->receipts->markFailed($receiptId, $e->getMessage());
                    }
                    $this->queue->archive($this->queueName, $job['msg_id']);
                }
                // иначе оставляем сообщение: vt истечёт и оно вернётся для ретрая
            }
        }
    }
}
