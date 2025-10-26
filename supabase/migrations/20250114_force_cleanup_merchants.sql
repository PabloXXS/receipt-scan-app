-- Миграция: принудительная очистка всех ссылок на merchants
-- Исправляет проблему, если предыдущая миграция не полностью применилась

-- 1. Удалить constraint если он всё ещё существует
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'receipts_merchant_id_fkey' 
        AND table_name = 'receipts'
    ) THEN
        ALTER TABLE receipts DROP CONSTRAINT receipts_merchant_id_fkey;
    END IF;
END $$;

-- 2. Удалить колонку merchant_id если она всё ещё существует
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'receipts' 
        AND column_name = 'merchant_id'
    ) THEN
        -- Сначала мигрируем данные если merchant_name пустой
        UPDATE receipts r
        SET merchant_name = COALESCE(r.merchant_name, m.name, 'Магазин')
        FROM merchants m
        WHERE r.merchant_id = m.id 
        AND (r.merchant_name IS NULL OR r.merchant_name = '');
        
        -- Теперь удаляем колонку
        ALTER TABLE receipts DROP COLUMN merchant_id;
    END IF;
END $$;

-- 3. Убедиться, что поле merchant_name существует
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'receipts' 
        AND column_name = 'merchant_name'
    ) THEN
        ALTER TABLE receipts ADD COLUMN merchant_name TEXT;
    END IF;
END $$;

-- 4. Убедиться, что поле store_confidence существует
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'receipts' 
        AND column_name = 'store_confidence'
    ) THEN
        ALTER TABLE receipts ADD COLUMN store_confidence NUMERIC(3,2);
    END IF;
END $$;

-- 5. Обновить комментарии
COMMENT ON COLUMN receipts.merchant_name IS 'Название магазина/торговой точки из OCR (не FK)';
COMMENT ON COLUMN receipts.store_confidence IS 'Уверенность в определении названия магазина (0-1)';
COMMENT ON TABLE merchants IS 'Таблица merchants больше не используется приложением (legacy)';

-- 6. Проверка: вывести текущую структуру receipts
DO $$
DECLARE
    col_name TEXT;
    col_type TEXT;
BEGIN
    RAISE NOTICE 'Текущая структура таблицы receipts:';
    FOR col_name, col_type IN 
        SELECT column_name, data_type 
        FROM information_schema.columns 
        WHERE table_name = 'receipts' 
        ORDER BY ordinal_position
    LOOP
        RAISE NOTICE '  - %: %', col_name, col_type;
    END LOOP;
END $$;

