<?php

declare(strict_types=1);

/**
 * Назначение: точка входа воркера — загрузка окружения и цикл чтения очереди pgmq.
 *
 * Роль в пайплайне: процесс-демон; на каждом проходе вызывает JobConsumer::tick.
 * Зависимости: Composer autoload, Support\Config, Queue\JobConsumer.
 * Заглушка: реальный цикл/wiring собирается в итерации воркера.
 */

require __DIR__ . '/../vendor/autoload.php';

// TODO(worker): загрузить .env (vlucas/phpdotenv), собрать зависимости и
// запустить бесконечный цикл JobConsumer::tick().
fwrite(STDOUT, "ChekiPrices worker — скелет. Логика обработки не реализована.\n");
