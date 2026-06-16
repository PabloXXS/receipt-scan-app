-- Миграция: scan — статус review + RPC confirm_receipt (зона A).
-- Зона доступа: A (приватные данные; RLS по auth.uid() = user_id).
-- Инвариант приватности: зона A; в зону C (prices) отсюда ничего не уходит.
--
-- Поток статусов: pending → processing → review → done | failed.
-- Воркер (service-role) пишет позиции и ставит review; клиент подтверждает через RPC.

-- 1. Расширяем допустимые статусы значением 'review'.
alter table public.receipts drop constraint if exists receipts_status_check;
alter table public.receipts add constraint receipts_status_check
  check (status in ('pending', 'processing', 'review', 'done', 'failed'));

-- 2. RPC подтверждения чека после ревью.
--    SECURITY DEFINER: обходит запрет клиентского UPDATE receipts, но строго
--    проверяет владение через auth.uid() и гейт статуса (только review → done).
create or replace function public.confirm_receipt(
  p_receipt_id uuid,
  p_items jsonb
)
returns public.receipts
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid     uuid := auth.uid();
  v_receipt public.receipts;
  v_total   numeric(12, 2);
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  -- Владение + блокировка строки. RLS под SECURITY DEFINER не действует,
  -- поэтому проверяем принадлежность явно.
  select * into v_receipt
    from public.receipts
   where id = p_receipt_id and user_id = v_uid
     for update;
  if not found then
    raise exception 'receipt % not found or not owned', p_receipt_id
      using errcode = '42501';
  end if;

  -- Гейт статуса: подтверждаем только из review.
  if v_receipt.status <> 'review' then
    raise exception 'receipt % is not in review status (%)', p_receipt_id, v_receipt.status
      using errcode = '22023';
  end if;

  -- Заменяем позиции на подтверждённые пользователем.
  delete from public.receipt_items where receipt_id = p_receipt_id;
  insert into public.receipt_items
    (receipt_id, raw_name, qty, unit_price, sum)
  select
    p_receipt_id,
    it->>'raw_name',
    coalesce(nullif(it->>'qty', '')::numeric, 1),
    nullif(it->>'unit_price', '')::numeric,
    nullif(it->>'sum', '')::numeric
  from jsonb_array_elements(coalesce(p_items, '[]'::jsonb)) as it;
  -- user_id/family_id проставит триггер receipt_items_fill_owner из auth.uid().

  -- Пересчитываем итог из подтверждённых позиций (авторитетный источник).
  select coalesce(sum(sum), 0)
    into v_total
    from public.receipt_items
   where receipt_id = p_receipt_id;

  update public.receipts
     set status = 'done', total = v_total
   where id = p_receipt_id
   returning * into v_receipt;

  return v_receipt;
end;
$$;

-- RPC вызывается клиентом → доступен authenticated (в отличие от триггерных функций).
revoke execute on function public.confirm_receipt(uuid, jsonb) from public, anon;
grant execute on function public.confirm_receipt(uuid, jsonb) to authenticated;
