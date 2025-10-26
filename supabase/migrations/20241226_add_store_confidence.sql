-- Добавляем поле store_confidence в таблицу receipts
-- для хранения уверенности в определении названия магазина

alter table receipts 
add column if not exists store_confidence numeric(3,2) 
check (store_confidence >= 0 and store_confidence <= 1);

-- Добавляем комментарий к полю
comment on column receipts.store_confidence is 'Уверенность в определении названия магазина (0-1)';
