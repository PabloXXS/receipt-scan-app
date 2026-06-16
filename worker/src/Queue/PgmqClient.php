<?php

declare(strict_types=1);

/**
 * Назначение: клиент очереди pgmq через PostgREST RPC-обёртки (service-role).
 *
 * Роль в пайплайне: транспорт задач между Postgres-триггером и воркером.
 * Зависимости: Supabase\SupabaseClient (RPC pgmq_read_jobs/pgmq_delete_job/pgmq_archive_job).
 */

namespace ChekiPrices\Worker\Queue;

use ChekiPrices\Worker\Supabase\SupabaseClient;

/**
 * Низкоуровневые операции над очередью pgmq поверх RPC-обёрток.
 */
class PgmqClient
{
    public function __construct(private readonly SupabaseClient $supabase)
    {
    }

    /**
     * Читает до $limit сообщений с visibility-timeout (секунды).
     *
     * @return list<array{msg_id:int, read_ct:int, message:array<string,mixed>}>
     */
    public function read(string $queue, int $visibilityTimeout, int $limit = 1): array
    {
        $rows = $this->supabase->rpc('pgmq_read_jobs', [
            'p_queue' => $queue,
            'p_vt' => $visibilityTimeout,
            'p_qty' => $limit,
        ]);
        $jobs = [];
        foreach ($rows as $row) {
            /** @var array{msg_id:int,read_ct:int,message:array<string,mixed>} $row */
            $jobs[] = [
                'msg_id' => (int) $row['msg_id'],
                'read_ct' => (int) $row['read_ct'],
                'message' => (array) $row['message'],
            ];
        }
        return $jobs;
    }

    /** Удаляет успешно обработанное сообщение. */
    public function delete(string $queue, int $msgId): void
    {
        $this->supabase->rpc('pgmq_delete_job', ['p_queue' => $queue, 'p_msg_id' => $msgId]);
    }

    /** Архивирует сообщение, исчерпавшее попытки. */
    public function archive(string $queue, int $msgId): void
    {
        $this->supabase->rpc('pgmq_archive_job', ['p_queue' => $queue, 'p_msg_id' => $msgId]);
    }
}
