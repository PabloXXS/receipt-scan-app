<?php

declare(strict_types=1);

/**
 * Назначение: логгер воркера (тонкая обёртка над monolog, PSR-3).
 *
 * Роль в пайплайне: инфраструктура наблюдаемости; пишет в stderr.
 * Зависимости: monolog/monolog, psr/log.
 */

namespace ChekiPrices\Worker\Support;

use Monolog\Handler\StreamHandler;
use Monolog\Level;
use Monolog\Logger as Monolog;
use Psr\Log\LoggerInterface;

/**
 * Тонкая обёртка над monolog с методами info/error.
 *
 * Не логировать секреты и service-role ключ.
 */
final class Logger
{
    private readonly LoggerInterface $logger;

    public function __construct(string $level = 'info')
    {
        $this->logger = self::create($level);
    }

    /**
     * Создаёт PSR-3 логгер с заданным уровнем, пишущий в stderr.
     */
    public static function create(string $level = 'info'): LoggerInterface
    {
        $monolog = new Monolog('worker');
        $monolog->pushHandler(new StreamHandler('php://stderr', Level::fromName(ucfirst($level))));
        return $monolog;
    }

    /**
     * Информационное сообщение.
     *
     * @param array<string,mixed> $context
     */
    public function info(string $message, array $context = []): void
    {
        $this->logger->info($message, $context);
    }

    /**
     * Сообщение об ошибке.
     *
     * @param array<string,mixed> $context
     */
    public function error(string $message, array $context = []): void
    {
        $this->logger->error($message, $context);
    }
}
