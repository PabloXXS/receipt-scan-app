-- Миграция: убедиться что колонка status существует в таблице receipts
-- Если колонка отсутствует - добавить её

DO $$
BEGIN
    -- Проверяем, существует ли колонка status
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'receipts' 
        AND column_name = 'status'
    ) THEN
        -- Добавляем колонку status если её нет
        ALTER TABLE receipts 
        ADD COLUMN status text NOT NULL DEFAULT 'processing'
        CHECK (status IN ('processing', 'ready', 'failed'));
        
        -- Создаём индекс для производительности
        CREATE INDEX IF NOT EXISTS idx_receipts_status ON receipts(status);
        
        RAISE NOTICE '✓ Колонка status успешно добавлена в таблицу receipts';
    ELSE
        RAISE NOTICE '✓ Колонка status уже существует в таблице receipts';
    END IF;
END $$;

-- Обновляем статистику
ANALYZE receipts;

-- Уведомляем PostgREST о перезагрузке схемы
NOTIFY pgrst, 'reload schema';

