-- Команда для перезагрузки схемы PostgREST
NOTIFY pgrst, 'reload schema';

-- Проверка текущей схемы receipts
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'receipts'
  AND column_name IN ('merchant_id', 'merchant_name')
ORDER BY column_name;
