-- ================================================
-- Исправление RLS политик для таблицы merchants
-- Выполните этот скрипт в Supabase SQL Editor
-- ================================================

-- Шаг 1: Проверяем текущие политики
DO $$ 
BEGIN
    RAISE NOTICE '=== Текущие политики для merchants ===';
END $$;

SELECT 
    policyname,
    cmd as "Команда (SELECT/INSERT/UPDATE/DELETE)"
FROM pg_policies 
WHERE tablename = 'merchants'
ORDER BY policyname;

-- Шаг 2: Удаляем все существующие политики для merchants
DROP POLICY IF EXISTS "Users can view all merchants" ON merchants;
DROP POLICY IF EXISTS "Users can create merchants" ON merchants;
DROP POLICY IF EXISTS "Users can update merchants" ON merchants;
DROP POLICY IF EXISTS "Users can delete merchants" ON merchants;
DROP POLICY IF EXISTS "Enable read access for all users" ON merchants;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON merchants;

-- Шаг 3: Убеждаемся что RLS включён
ALTER TABLE merchants ENABLE ROW LEVEL SECURITY;

-- Шаг 4: Создаём политики заново
-- Политика на чтение (SELECT) - доступно всем
CREATE POLICY "Users can view all merchants" 
ON merchants
FOR SELECT
USING (true);

-- Политика на создание (INSERT) - доступно только аутентифицированным пользователям
CREATE POLICY "Users can create merchants" 
ON merchants
FOR INSERT 
TO authenticated
WITH CHECK (true);

-- Политика на обновление (UPDATE) - доступно только аутентифицированным пользователям
CREATE POLICY "Users can update merchants"
ON merchants
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Политика на удаление (DELETE) - доступно только аутентифицированным пользователям
-- Примечание: в приложении используется мягкое удаление через UPDATE is_deleted
CREATE POLICY "Users can delete merchants"
ON merchants
FOR DELETE
TO authenticated
USING (true);

-- Шаг 5: Проверяем что политики созданы
DO $$ 
BEGIN
    RAISE NOTICE '=== Новые политики для merchants ===';
END $$;

SELECT 
    policyname,
    cmd as "Команда",
    roles as "Роли"
FROM pg_policies 
WHERE tablename = 'merchants'
ORDER BY policyname;

-- Шаг 6: Тест - попробуем создать тестовую категорию и удалить её
DO $$ 
DECLARE
    test_id uuid;
BEGIN
    RAISE NOTICE '=== Тест создания категории ===';
    
    -- Создаём тестовую категорию
    INSERT INTO merchants (name, icon_name) 
    VALUES ('__TEST_CATEGORY__', 'folder')
    RETURNING id INTO test_id;
    
    RAISE NOTICE 'Тестовая категория создана с ID: %', test_id;
    
    -- Удаляем тестовую категорию
    DELETE FROM merchants WHERE id = test_id;
    
    RAISE NOTICE 'Тестовая категория удалена';
    RAISE NOTICE 'ТЕСТ ПРОЙДЕН! Политики работают корректно.';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'ОШИБКА ПРИ ТЕСТЕ: %', SQLERRM;
    RAISE NOTICE 'Проверьте что вы выполняете скрипт под аутентифицированным пользователем.';
END $$;

-- ================================================
-- Готово!
-- Если тест прошёл успешно - попробуйте создать 
-- чек в новую категорию в приложении
-- ================================================

