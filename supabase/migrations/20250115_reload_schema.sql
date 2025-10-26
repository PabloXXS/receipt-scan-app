-- Миграция: очистка и обновление статистики БД
-- Это заставит PostgREST обновить кэш схемы

-- Полная очистка и анализ таблицы receipts
VACUUM FULL ANALYZE receipts;

-- Обновить статистику для всех таблиц
ANALYZE;

-- Отправить уведомление PostgREST о перезагрузке схемы
NOTIFY pgrst, 'reload schema';

-- Вывести текущую схему receipts для подтверждения
DO $$
DECLARE
    has_merchant_id BOOLEAN;
    has_merchant_name BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'receipts' AND column_name = 'merchant_id'
    ) INTO has_merchant_id;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'receipts' AND column_name = 'merchant_name'
    ) INTO has_merchant_name;
    
    RAISE NOTICE '=== Проверка схемы receipts ===';
    RAISE NOTICE 'merchant_id существует: %', has_merchant_id;
    RAISE NOTICE 'merchant_name существует: %', has_merchant_name;
    
    IF has_merchant_id THEN
        RAISE EXCEPTION 'ОШИБКА: merchant_id всё ещё существует в таблице receipts!';
    END IF;
    
    IF NOT has_merchant_name THEN
        RAISE EXCEPTION 'ОШИБКА: merchant_name не найден в таблице receipts!';
    END IF;
    
    RAISE NOTICE 'Схема корректна!';
END $$;

