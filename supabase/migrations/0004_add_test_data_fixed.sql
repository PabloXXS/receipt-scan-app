-- Добавление тестовых данных для демонстрации группировки по магазинам
-- Используем фиксированный user_id для тестовых данных

-- Добавляем тестовые магазины
INSERT INTO merchants (id, name, inn, created_at, updated_at) VALUES 
  ('550e8400-e29b-41d4-a716-446655440001', 'ProStore', '1234567890', now(), now()),
  ('550e8400-e29b-41d4-a716-446655440002', 'Пятерочка', '0987654321', now(), now()),
  ('550e8400-e29b-41d4-a716-446655440003', 'Магнит', '1122334455', now(), now()),
  ('550e8400-e29b-41d4-a716-446655440004', 'Другое', null, now(), now())
ON CONFLICT (id) DO NOTHING;

-- Получаем первый пользователя из auth.users для тестовых данных
DO $$
DECLARE
    test_user_id uuid;
    receipt_count INTEGER;
BEGIN
    -- Получаем ID первого пользователя
    SELECT id INTO test_user_id FROM auth.users LIMIT 1;
    
    -- Если пользователей нет, создаем тестового пользователя
    IF test_user_id IS NULL THEN
        INSERT INTO auth.users (id, email, created_at, updated_at, email_confirmed_at)
        VALUES ('00000000-0000-0000-0000-000000000001', 'pablovins@mail.ru', now(), now(), now());
        test_user_id := '00000000-0000-0000-0000-000000000001';
    END IF;
    
    -- Проверяем, есть ли уже чеки
    SELECT COUNT(*) INTO receipt_count FROM receipts;
    
    -- Если чеков нет, добавляем тестовые
    IF receipt_count = 0 THEN
        -- Чеки для ProStore
        INSERT INTO receipts (id, user_id, merchant_id, purchase_date, purchase_time, total, currency, status, created_at, updated_at) VALUES 
          ('660e8400-e29b-41d4-a716-446655440001', test_user_id, '550e8400-e29b-41d4-a716-446655440001', '2024-01-15', '14:30:00', 1250.50, 'RUB', 'ready', now() - interval '5 days', now() - interval '5 days'),
          ('660e8400-e29b-41d4-a716-446655440002', test_user_id, '550e8400-e29b-41d4-a716-446655440001', '2024-01-14', '10:15:00', 890.30, 'RUB', 'ready', now() - interval '6 days', now() - interval '6 days'),
          ('660e8400-e29b-41d4-a716-446655440003', test_user_id, '550e8400-e29b-41d4-a716-446655440001', '2024-01-13', '16:45:00', 2100.75, 'RUB', 'ready', now() - interval '7 days', now() - interval '7 days'),
          
          -- Чеки для Пятерочки
          ('660e8400-e29b-41d4-a716-446655440004', test_user_id, '550e8400-e29b-41d4-a716-446655440002', '2024-01-12', '12:20:00', 445.20, 'RUB', 'ready', now() - interval '8 days', now() - interval '8 days'),
          ('660e8400-e29b-41d4-a716-446655440005', test_user_id, '550e8400-e29b-41d4-a716-446655440002', '2024-01-11', '18:30:00', 320.80, 'RUB', 'ready', now() - interval '9 days', now() - interval '9 days'),
          
          -- Чеки для Магнита
          ('660e8400-e29b-41d4-a716-446655440006', test_user_id, '550e8400-e29b-41d4-a716-446655440003', '2024-01-10', '09:15:00', 678.90, 'RUB', 'ready', now() - interval '10 days', now() - interval '10 days'),
          ('660e8400-e29b-41d4-a716-446655440007', test_user_id, '550e8400-e29b-41d4-a716-446655440003', '2024-01-09', '15:45:00', 234.50, 'RUB', 'ready', now() - interval '11 days', now() - interval '11 days'),
          
          -- Чеки для "Другое"
          ('660e8400-e29b-41d4-a716-446655440008', test_user_id, '550e8400-e29b-41d4-a716-446655440004', '2024-01-08', '11:30:00', 150.00, 'RUB', 'ready', now() - interval '12 days', now() - interval '12 days');
          
        -- Добавляем позиции для чеков
        INSERT INTO receipt_items (receipt_id, name, qty, price, created_at, updated_at) VALUES 
          -- Позиции для ProStore чеков
          ('660e8400-e29b-41d4-a716-446655440001', 'Ноутбук', 1, 1250.50, now() - interval '5 days', now() - interval '5 days'),
          ('660e8400-e29b-41d4-a716-446655440002', 'Мышь', 1, 450.30, now() - interval '6 days', now() - interval '6 days'),
          ('660e8400-e29b-41d4-a716-446655440002', 'Клавиатура', 1, 440.00, now() - interval '6 days', now() - interval '6 days'),
          ('660e8400-e29b-41d4-a716-446655440003', 'Монитор', 1, 1500.75, now() - interval '7 days', now() - interval '7 days'),
          ('660e8400-e29b-41d4-a716-446655440003', 'Коврик для мыши', 1, 600.00, now() - interval '7 days', now() - interval '7 days'),
          
          -- Позиции для Пятерочки
          ('660e8400-e29b-41d4-a716-446655440004', 'Хлеб', 2, 45.20, now() - interval '8 days', now() - interval '8 days'),
          ('660e8400-e29b-41d4-a716-446655440004', 'Молоко', 3, 78.50, now() - interval '8 days', now() - interval '8 days'),
          ('660e8400-e29b-41d4-a716-446655440004', 'Яйца', 1, 89.00, now() - interval '8 days', now() - interval '8 days'),
          ('660e8400-e29b-41d4-a716-446655440004', 'Сыр', 1, 232.50, now() - interval '8 days', now() - interval '8 days'),
          ('660e8400-e29b-41d4-a716-446655440005', 'Йогурт', 4, 39.90, now() - interval '9 days', now() - interval '9 days'),
          ('660e8400-e29b-41d4-a716-446655440005', 'Печенье', 2, 65.00, now() - interval '9 days', now() - interval '9 days'),
          ('660e8400-e29b-41d4-a716-446655440005', 'Сок', 1, 155.90, now() - interval '9 days', now() - interval '9 days'),
          
          -- Позиции для Магнита
          ('660e8400-e29b-41d4-a716-446655440006', 'Кофе', 1, 299.90, now() - interval '10 days', now() - interval '10 days'),
          ('660e8400-e29b-41d4-a716-446655440006', 'Чай', 2, 189.50, now() - interval '10 days', now() - interval '10 days'),
          ('660e8400-e29b-41d4-a716-446655440006', 'Печенье', 1, 189.50, now() - interval '10 days', now() - interval '10 days'),
          ('660e8400-e29b-41d4-a716-446655440007', 'Конфеты', 1, 234.50, now() - interval '11 days', now() - interval '11 days'),
          
          -- Позиции для "Другое"
          ('660e8400-e29b-41d4-a716-446655440008', 'Прочие товары', 1, 150.00, now() - interval '12 days', now() - interval '12 days');
    END IF;
END $$;
