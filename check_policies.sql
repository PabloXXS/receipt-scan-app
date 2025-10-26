-- Скрипт для проверки RLS политик на таблице merchants
-- Выполните в Supabase SQL Editor

-- 1. Проверяем, включён ли RLS для таблицы merchants
SELECT 
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables
WHERE tablename = 'merchants';

-- 2. Проверяем все политики для таблицы merchants
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'merchants'
ORDER BY policyname;

-- 3. Проверяем права текущего пользователя
SELECT current_user, session_user;

-- 4. Тестовый запрос на чтение
SELECT id, name, icon_name 
FROM merchants 
LIMIT 5;

-- 5. Тестовый запрос на создание (закомментирован, раскомментируйте для теста)
-- INSERT INTO merchants (name, icon_name) 
-- VALUES ('Test Category', 'folder')
-- RETURNING id, name, icon_name;

-- Ожидаемые политики:
-- 1. "Users can view all merchants" - SELECT для всех
-- 2. "Users can create merchants" - INSERT для authenticated
-- 3. "Users can update merchants" - UPDATE для authenticated

