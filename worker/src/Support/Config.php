<?php

declare(strict_types=1);

/**
 * Назначение: доступ к конфигурации воркера из окружения (.env).
 *
 * Роль в пайплайне: инфраструктура; читается на старте bin/worker.php.
 * Зависимости: vlucas/phpdotenv (загрузка .env в bin/worker.php).
 */

namespace ChekiPrices\Worker\Support;

/**
 * Тонкая обёртка над переменными окружения воркера.
 */
final class Config
{
    /**
     * Возвращает значение переменной окружения или значение по умолчанию.
     */
    public function get(string $key, ?string $default = null): ?string
    {
        $value = $_ENV[$key] ?? getenv($key);
        return $value === false || $value === null ? $default : (string) $value;
    }

    /**
     * Возвращает обязательную переменную; бросает, если она не задана.
     *
     * @throws \RuntimeException если переменная отсутствует или пуста.
     */
    public function require(string $key): string
    {
        $value = $this->get($key);
        if ($value === null || $value === '') {
            throw new \RuntimeException("Missing required env: {$key}");
        }
        return $value;
    }

    /**
     * Возвращает целочисленную переменную окружения со значением по умолчанию.
     */
    public function int(string $key, int $default): int
    {
        $value = $this->get($key);
        return $value === null || $value === '' ? $default : (int) $value;
    }
}
