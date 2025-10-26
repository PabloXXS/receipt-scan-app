-- Миграция: принудительная перезагрузка PostgREST схемы
-- Изменяем и возвращаем обратно настройку search_path чтобы форсировать reload

-- 1. Временно изменяем search_path
ALTER DATABASE postgres SET search_path TO public, extensions;

-- 2. Возвращаем обратно
ALTER DATABASE postgres SET search_path TO "\$user", public, extensions;

-- 3. Пересоздаём view для receipts (это заставит PostgREST обновить схему)
DROP VIEW IF EXISTS receipts_view CASCADE;
CREATE OR REPLACE VIEW receipts_view AS 
SELECT 
    id,
    user_id,
    merchant_name,  -- ЗДЕСЬ НЕТ merchant_id!
    purchase_date,
    purchase_time,
    total,
    currency,
    status,
    source_file_id,
    error_text,
    store_confidence,
    created_at,
    updated_at,
    is_deleted
FROM receipts;

-- 4. Даём права на view
GRANT SELECT ON receipts_view TO anon, authenticated;

-- 5. Отправляем несколько NOTIFY подряд (иногда PostgREST пропускает первый)
NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';
NOTIFY pgrst, 'reload schema';

-- 6. Обновляем статистику таблицы receipts
ANALYZE receipts;

-- 7. Выводим информацию о схеме
DO $$
DECLARE
    col RECORD;
BEGIN
    RAISE NOTICE '=== Актуальная схема таблицы receipts ===';
    FOR col IN 
        SELECT column_name, data_type 
        FROM information_schema.columns 
        WHERE table_name = 'receipts' 
        ORDER BY ordinal_position
    LOOP
        RAISE NOTICE 'Column: % (type: %)', col.column_name, col.data_type;
    END LOOP;
    
    -- Проверка наличия merchant_id
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'receipts' AND column_name = 'merchant_id'
    ) THEN
        RAISE EXCEPTION 'КРИТИЧЕСКАЯ ОШИБКА: merchant_id всё ещё существует!';
    ELSE
        RAISE NOTICE '✓ merchant_id успешно удалён';
    END IF;
    
    -- Проверка наличия merchant_name
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'receipts' AND column_name = 'merchant_name'
    ) THEN
        RAISE EXCEPTION 'КРИТИЧЕСКАЯ ОШИБКА: merchant_name отсутствует!';
    ELSE
        RAISE NOTICE '✓ merchant_name присутствует';
    END IF;
END $$;

