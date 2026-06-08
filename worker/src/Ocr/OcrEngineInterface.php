<?php

declare(strict_types=1);

/**
 * Назначение: контракт OCR-движка (фото → текст).
 *
 * Роль в пайплайне: используется OcrFallbackStep, когда фискальные данные не получены.
 * Зависимости: нет.
 */

namespace ChekiPrices\Worker\Ocr;

/**
 * Абстракция OCR-движка.
 */
interface OcrEngineInterface
{
    /**
     * Распознаёт текст с фотографии чека по пути в Storage.
     */
    public function recognize(string $photoPath): string;
}
