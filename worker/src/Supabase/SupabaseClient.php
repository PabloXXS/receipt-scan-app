<?php

declare(strict_types=1);

/**
 * Назначение: PostgREST/Storage-клиент поверх service-role ключа.
 *
 * Роль в пайплайне: единственный канал доступа воркера к БД/Storage (зоны A/B).
 * Зависимости: guzzlehttp/guzzle.
 */

namespace ChekiPrices\Worker\Supabase;

use GuzzleHttp\ClientInterface;

/**
 * Низкоуровневый клиент Supabase (service role): PostgREST, RPC и Storage.
 */
final class SupabaseClient
{
    public function __construct(
        private readonly string $url,
        private readonly string $serviceRoleKey,
        private readonly ClientInterface $http,
    ) {
    }

    /** @return array<string,string> */
    private function headers(): array
    {
        return [
            'apikey' => $this->serviceRoleKey,
            'Authorization' => 'Bearer ' . $this->serviceRoleKey,
            'Content-Type' => 'application/json',
        ];
    }

    /**
     * PostgREST-запрос к таблице/представлению.
     *
     * @param array<string,mixed> $options доп. опции guzzle (query/json/headers)
     * @return array<int|string,mixed>
     */
    public function request(string $method, string $path, array $options = []): array
    {
        /** @var array<string,string> $extraHeaders */
        $extraHeaders = $options['headers'] ?? [];
        $options['headers'] = array_merge($this->headers(), $extraHeaders);
        $resp = $this->http->request($method, $this->url . '/rest/v1/' . ltrim($path, '/'), $options);
        $body = (string) $resp->getBody();
        if ($body === '') {
            return [];
        }
        /** @var array<int|string,mixed> $decoded */
        $decoded = json_decode($body, true, 512, JSON_THROW_ON_ERROR);
        return $decoded;
    }

    /**
     * Вызов RPC-функции (POST /rest/v1/rpc/{fn}).
     *
     * @param array<string,mixed> $args
     * @return array<int|string,mixed>
     */
    public function rpc(string $function, array $args = []): array
    {
        return $this->request('POST', 'rpc/' . $function, ['json' => $args]);
    }

    /** Скачивает объект Storage (сырые байты). */
    public function downloadObject(string $bucket, string $path): string
    {
        $resp = $this->http->request(
            'GET',
            $this->url . '/storage/v1/object/' . $bucket . '/' . ltrim($path, '/'),
            ['headers' => [
                'Authorization' => 'Bearer ' . $this->serviceRoleKey,
                'apikey' => $this->serviceRoleKey,
            ]],
        );
        return (string) $resp->getBody();
    }
}
