<?php

declare(strict_types=1);

/**
 * Назначение: резолвит фискального провайдера по country_code.
 *
 * Роль в пайплайне: точка расширения «новая страна = новый класс + конфиг».
 * Зависимости: FiscalProviderInterface, config/providers.php, таблица fiscal_providers.
 */

namespace ChekiPrices\Worker\Fiscal;

/**
 * Фабрика фискальных провайдеров по коду страны.
 */
final class FiscalProviderFactory
{
    /**
     * @param array<string, string> $countryToProviderKey
     */
    public function __construct(
        private readonly array $countryToProviderKey,
    ) {
    }

    /**
     * Возвращает провайдера для указанной страны.
     *
     * @throws \RuntimeException пока не реализовано.
     */
    public function forCountry(string $countryCode): FiscalProviderInterface
    {
        throw new \RuntimeException('Not implemented');
    }
}
