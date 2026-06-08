<?php

declare(strict_types=1);

/**
 * Назначение: итог обработки одного чека (статус и опциональная ошибка).
 *
 * Роль в пайплайне: возвращается ReceiptProcessor в JobConsumer.
 * Зависимости: нет.
 */

namespace ChekiPrices\Worker\Pipeline;

/**
 * Результат прохода пайплайна по чеку.
 */
final readonly class ProcessingResult
{
    public function __construct(
        public string $status,
        public ?string $error = null,
    ) {
    }
}
