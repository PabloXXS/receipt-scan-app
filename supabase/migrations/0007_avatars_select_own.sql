-- Восстанавливаем SELECT для бакета avatars, но в безопасном виде.
--
-- В 0006 была убрана широкая публичная SELECT-политика (листинг всех файлов).
-- Однако загрузка аватара идёт с `upsert: true`, а upsert в Supabase Storage
-- читает метаданные объекта обратно — для этого нужен SELECT на строку
-- storage.objects. Без него POST /object/avatars/... возвращает 400.
--
-- Даём SELECT только на СВОЮ папку для authenticated (как у бакета receipts:
-- receipts_storage_select_own). Это не даёт листинг чужих файлов, поэтому
-- security-advisor `public_bucket_allows_listing` не срабатывает. Публичный
-- доступ по URL (`/object/public/avatars/...`) работает независимо от RLS.

create policy "avatars_select_own"
on storage.objects for select to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);
