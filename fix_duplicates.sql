-- ========================================
-- ИСПРАВЛЕНИЕ ДУБЛИКАТОВ КАТЕГОРИЙ
-- ========================================

-- Шаг 1: Найдем все дубликаты категорий
SELECT 
    name,
    COUNT(*) as count,
    STRING_AGG(id::text, ', ') as ids
FROM merchants
WHERE is_deleted = false
GROUP BY name
HAVING COUNT(*) > 1
ORDER BY count DESC;

-- Шаг 2: Для категории "test" - переносим все чеки на одну категорию
DO $$
DECLARE
    keep_id uuid := 'e2bdcba2-d525-4d32-a1c6-fceb188ae8f5'; -- Категория с чеками
    remove_id uuid := 'ae920326-5aae-4a35-8b69-92d7c99723dc'; -- Пустая категория
    moved_count int;
BEGIN
    -- Переносим чеки с пустой категории на заполненную (если есть)
    UPDATE receipts 
    SET merchant_id = keep_id
    WHERE merchant_id = remove_id 
    AND is_deleted = false;
    
    GET DIAGNOSTICS moved_count = ROW_COUNT;
    RAISE NOTICE 'Перенесено чеков: %', moved_count;
    
    -- Удаляем пустую категорию
    UPDATE merchants
    SET is_deleted = true
    WHERE id = remove_id;
    
    RAISE NOTICE 'Дубликат категории "test" удалён';
END $$;

-- Шаг 3: Добавляем уникальный индекс чтобы дубликаты больше не появлялись
CREATE UNIQUE INDEX IF NOT EXISTS idx_merchants_name_unique 
ON merchants(name) 
WHERE is_deleted = false;

-- Шаг 4: Проверяем результат
SELECT 
    id,
    name,
    (SELECT COUNT(*) FROM receipts WHERE merchant_id = merchants.id AND is_deleted = false) as receipts_count
FROM merchants
WHERE name = 'test' AND is_deleted = false;

-- Готово!
RAISE NOTICE 'Дубликаты устранены. Уникальный индекс добавлен.';

