-- Добавление поля icon_name в таблицу merchants для хранения выбранной иконки категории
-- Миграция для поддержки иконок категорий

-- Добавляем поле icon_name (название иконки)
ALTER TABLE merchants 
ADD COLUMN IF NOT EXISTS icon_name text DEFAULT 'folder';

-- Добавляем комментарий к полю
COMMENT ON COLUMN merchants.icon_name IS 'Название иконки для категории (используется для визуального отображения)';

-- Обновляем существующие записи, устанавливая иконку по умолчанию
UPDATE merchants 
SET icon_name = 'folder' 
WHERE icon_name IS NULL;

