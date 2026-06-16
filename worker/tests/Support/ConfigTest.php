<?php

declare(strict_types=1);

namespace ChekiPrices\Worker\Tests\Support;

use ChekiPrices\Worker\Support\Config;
use PHPUnit\Framework\TestCase;

final class ConfigTest extends TestCase
{
    public function testRequireReturnsValue(): void
    {
        $_ENV['CFG_X'] = 'hello';
        self::assertSame('hello', (new Config())->require('CFG_X'));
    }

    public function testRequireThrowsWhenMissing(): void
    {
        unset($_ENV['CFG_MISSING']);
        $this->expectException(\RuntimeException::class);
        (new Config())->require('CFG_MISSING');
    }

    public function testIntWithDefault(): void
    {
        unset($_ENV['CFG_INT']);
        self::assertSame(30, (new Config())->int('CFG_INT', 30));
        $_ENV['CFG_INT'] = '5';
        self::assertSame(5, (new Config())->int('CFG_INT', 30));
    }
}
