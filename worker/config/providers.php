<?php

declare(strict_types=1);

/**
 * Назначение: дефолтный мапинг country_code → provider_key.
 *
 * Роль в пайплайне: используется FiscalProviderFactory как фоллбэк к таблице
 * fiscal_providers.
 * Зависимости: нет.
 *
 * @return array<string, string>
 */

return [
    'RU' => 'ru_fns',
    'BY' => 'by',
    'KZ' => 'kz',
];
