-- Очистка чеков в статусах processing или failed
-- Эти чеки были созданы, но не завершены успешно

UPDATE receipts
SET is_deleted = true, updated_at = now()
WHERE status IN ('processing', 'failed')
  AND is_deleted = false;

-- Посмотреть количество очищенных записей
-- SELECT count(*) FROM receipts WHERE status IN ('processing', 'failed') AND is_deleted = true;

