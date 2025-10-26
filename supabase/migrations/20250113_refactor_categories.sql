-- Миграция: рефакторинг логики категорий
-- Убираем merchant_id из receipts, добавляем merchant_name
-- Категории товаров (categories) становятся основными для группировки items

-- 1. Добавить поле merchant_name в receipts
ALTER TABLE receipts ADD COLUMN IF NOT EXISTS merchant_name TEXT;

-- 2. Мигрировать данные из merchants в merchant_name (для существующих чеков)
-- Только если колонка merchant_id существует
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'receipts' 
        AND column_name = 'merchant_id'
    ) THEN
        UPDATE receipts r
        SET merchant_name = m.name
        FROM merchants m
        WHERE r.merchant_id = m.id AND r.merchant_name IS NULL;
        
        RAISE NOTICE '✓ Данные из merchant_id мигрированы в merchant_name';
    ELSE
        RAISE NOTICE '✓ Колонка merchant_id не существует, миграция данных не требуется';
    END IF;
END $$;

-- 3. Удалить foreign key constraint и колонку merchant_id
ALTER TABLE receipts DROP CONSTRAINT IF EXISTS receipts_merchant_id_fkey;
ALTER TABLE receipts DROP COLUMN IF EXISTS merchant_id;

-- 4. Убедиться, что в таблице categories есть базовые категории товаров
INSERT INTO categories (name) VALUES 
  ('Продукты'),
  ('Напитки'),
  ('Хлебобулочные изделия'),
  ('Молочные продукты'),
  ('Мясо и рыба'),
  ('Овощи и фрукты'),
  ('Бытовая химия'),
  ('Косметика'),
  ('Лекарства'),
  ('Снеки'),
  ('Замороженные продукты'),
  ('Кондитерские изделия'),
  ('Детское питание'),
  ('Бакалея'),
  ('Консервы'),
  ('Прочее')
ON CONFLICT (name) DO NOTHING;

-- 5. Комментарии для ясности схемы
COMMENT ON COLUMN receipts.merchant_name IS 'Название магазина/торговой точки из OCR (не FK)';
COMMENT ON TABLE categories IS 'Категории товаров для группировки позиций чеков (receipt_items)';
COMMENT ON TABLE merchants IS 'Таблица merchants теперь не используется приложением (legacy)';

