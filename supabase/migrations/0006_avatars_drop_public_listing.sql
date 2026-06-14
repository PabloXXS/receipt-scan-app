-- Хардненинг бакета avatars: убираем широкую SELECT-политику.
--
-- Публичный бакет (`public=true`) отдаёт объекты по публичному URL
-- (`/object/public/avatars/...`) без проверки RLS, поэтому политика
-- `avatars_public_read` для доступа по URL не нужна. Её наличие лишь
-- разрешает листинг всех файлов бакета (а пути содержат `auth.uid`),
-- что и отметил security-advisor (public_bucket_allows_listing).
-- Запись/изменение/удаление по-прежнему ограничены своей папкой
-- (политики avatars_insert/update/delete_own из 0005).

drop policy if exists "avatars_public_read" on storage.objects;
