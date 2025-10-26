-- Удалить все чеки в статусе processing или failed (они могли остаться со старой схемой)
DELETE FROM receipt_items 
WHERE receipt_id IN (
  SELECT id FROM receipts WHERE status IN ('processing', 'failed')
);

DELETE FROM receipts 
WHERE status IN ('processing', 'failed');

-- Показать оставшиеся чеки
SELECT id, status, merchant_name, created_at 
FROM receipts 
ORDER BY created_at DESC 
LIMIT 10;
