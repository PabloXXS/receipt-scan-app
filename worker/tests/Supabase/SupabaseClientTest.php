<?php

declare(strict_types=1);

namespace ChekiPrices\Worker\Tests\Supabase;

use ChekiPrices\Worker\Supabase\SupabaseClient;
use GuzzleHttp\Client;
use GuzzleHttp\Handler\MockHandler;
use GuzzleHttp\HandlerStack;
use GuzzleHttp\Psr7\Request;
use GuzzleHttp\Psr7\Response;
use PHPUnit\Framework\TestCase;

final class SupabaseClientTest extends TestCase
{
    /** @var list<array{request:Request}> */
    private array $recorded = [];

    private function client(MockHandler $mock): SupabaseClient
    {
        $stack = HandlerStack::create($mock);
        $stack->push(\GuzzleHttp\Middleware::history($this->recorded));
        $http = new Client(['handler' => $stack]);
        return new SupabaseClient('https://x.supabase.co', 'svc-key', $http);
    }

    public function testRpcSendsServiceRoleHeadersAndDecodesJson(): void
    {
        $mock = new MockHandler([new Response(200, [], '[{"msg_id":7}]')]);
        $client = $this->client($mock);

        $out = $client->rpc('pgmq_read_jobs', ['p_queue' => 'q', 'p_vt' => 30, 'p_qty' => 5]);

        self::assertSame([['msg_id' => 7]], $out);
        $req = $this->recorded[0]['request'];
        self::assertSame('POST', $req->getMethod());
        self::assertStringContainsString('/rest/v1/rpc/pgmq_read_jobs', (string) $req->getUri());
        self::assertSame('svc-key', $req->getHeaderLine('apikey'));
        self::assertSame('Bearer svc-key', $req->getHeaderLine('Authorization'));
    }

    public function testDownloadObjectReturnsRawBytes(): void
    {
        $mock = new MockHandler([new Response(200, [], "\xFF\xD8\xFFbytes")]);
        $client = $this->client($mock);

        $bytes = $client->downloadObject('receipts', 'uid/ts.jpg');

        self::assertSame("\xFF\xD8\xFFbytes", $bytes);
        $req = $this->recorded[0]['request'];
        self::assertStringContainsString('/storage/v1/object/receipts/uid/ts.jpg', (string) $req->getUri());
        self::assertSame('Bearer svc-key', $req->getHeaderLine('Authorization'));
    }
}
