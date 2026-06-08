<?php

declare(strict_types=1);

/**
 * Назначение: PostgREST-клиент поверх service-role ключа.
 *
 * Роль в пайплайне: единственный канал доступа воркера к БД (зоны A/B/C).
 * Зависимости: guzzlehttp/guzzle, Support\Config.
 */

namespace ChekiPrices\Worker\Supabase;

/**
 * Низкоуровневый клиент Supabase (service role).
 */
final class SupabaseClient
{
    public function __construct(
        private readonly string $url,
        private readonly string $serviceRoleKey,
    ) {
    }

    /**
     * Выполняет запрос к PostgREST.
     *
     * @param array<string, mixed> $options
     * @return array<int|string, mixed>
     * @throws \RuntimeException пока не реализовано.
     */
    public function request(string $method, string $path, array $options = []): array
    {
        throw new \RuntimeException('Not implemented');
    }
}
