-- Миграция: scan — receipt_items_fill_owner сохраняет владельца под service-role (зона A).
-- Зона доступа: A (receipt_items; RLS по auth.uid() = user_id).
-- Инвариант приватности: зона A; в зону C (prices) отсюда ничего не уходит.
--
-- Проблема: триггер receipt_items_fill_owner (0003) безусловно делал
-- new.user_id := auth.uid(). PHP-воркер вставляет позиции под service-role-ключом,
-- где auth.uid() IS NULL → владелец затирался в NULL и падал NOT NULL.
--
-- Фикс: клиентский путь (authenticated) по-прежнему НЕ может подделать владельца —
-- user_id принудительно = auth.uid(); service-role путь (auth.uid() IS NULL)
-- сохраняет явно переданные воркером user_id/family_id.

create or replace function public.receipt_items_fill_owner()
returns trigger language plpgsql security definer set search_path = public, pg_temp as $$
begin
  -- coalesce: клиент (authenticated) → auth.uid(); воркер (service-role) → переданный user_id.
  new.user_id := coalesce(auth.uid(), new.user_id);
  if auth.uid() is not null then
    select p.family_id into new.family_id from public.profiles p where p.id = auth.uid();
  end if;
  -- под service-role (auth.uid() IS NULL) сохраняем переданные воркером user_id/family_id
  return new;
end; $$;

revoke execute on function public.receipt_items_fill_owner() from public, anon, authenticated;
