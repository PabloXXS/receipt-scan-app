<?php

declare(strict_types=1);

/**
 * Назначение: клиент очереди pgmq (read/delete/archive).
 *
 * Роль в пайплайне: транспорт задач между Postgres-триггером и воркером.
 * Зависимости: PDO/PostgREST через SupabaseClient (внедряется позже).
 */

namespace ChekiPrices\Worker\Queue;

/**
 * Низкоуровневые операции над очередью pgmq.
 */
final class PgmqClient
{
    /**
     * Читает до $limit сообщений с visibility-timeout (секунды).
     *
     * @return array<int, array{msg_id:int, message:array<string,mixed>}>
     * @throws \RuntimeException пока не реализовано.
     */
    public function read(string $queue, int $visibilityTimeout, int $limit = 1): array
    {
        throw new \RuntimeException('Not implemented');
    }

    /**
     * Удаляет успешно обработанное сообщение.
     *
     * @throws \RuntimeException пока не реализовано.
     */
    public function delete(string $queue, int $msgId): void
    {
        throw new \RuntimeException('Not implemented');
    }

    /**
     * Архивирует сообщение, исчерпавшее попытки.
     *
     * @throws \RuntimeException пока не реализовано.
     */
    public function archive(string $queue, int $msgId): void
    {
        throw new \RuntimeException('Not implemented');
    }
}
