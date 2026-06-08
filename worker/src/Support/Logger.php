<?php

declare(strict_types=1);

/**
 * Назначение: фабрика логгера воркера.
 *
 * Роль в пайплайне: инфраструктура наблюдаемости.
 * Зависимости: monolog/monolog.
 */

namespace ChekiPrices\Worker\Support;

use Psr\Log\LoggerInterface;

/**
 * Создаёт настроенный PSR-3 логгер.
 */
final class Logger
{
    /**
     * Создаёт логгер с заданным уровнем.
     *
     * @throws \RuntimeException пока не реализовано.
     */
    public static function create(string $level = 'info'): LoggerInterface
    {
        throw new \RuntimeException('Not implemented');
    }
}
