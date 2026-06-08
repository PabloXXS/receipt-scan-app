<?php

declare(strict_types=1);

/**
 * Назначение: цикл обработки очереди — read → handle → delete | retry/archive.
 *
 * Роль в пайплайне: верхнеуровневый драйвер; вызывает ReceiptProcessor.
 * Зависимости: PgmqClient, Pipeline\ReceiptProcessor.
 */

namespace ChekiPrices\Worker\Queue;

use ChekiPrices\Worker\Pipeline\ReceiptProcessor;

/**
 * Потребитель очереди pgmq: один проход цикла читает и обрабатывает задачи.
 */
final class JobConsumer
{
    public function __construct(
        private readonly PgmqClient $queue,
        private readonly ReceiptProcessor $processor,
    ) {
    }

    /**
     * Один проход: читает пачку сообщений и обрабатывает каждое.
     *
     * @throws \RuntimeException пока не реализовано.
     */
    public function tick(string $queue, int $visibilityTimeout): void
    {
        throw new \RuntimeException('Not implemented');
    }
}
