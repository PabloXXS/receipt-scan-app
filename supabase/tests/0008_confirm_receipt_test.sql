-- supabase/tests/0008_confirm_receipt_test.sql
-- Запуск: MCP execute_sql целиком (содержит rollback в конце — данные не остаются).
begin;

-- Тестовый пользователь + профиль.
insert into auth.users (id, email)
values ('00000000-0000-0000-0000-0000000000aa', 'cr-test@example.com');
insert into public.profiles (id, country_code)
values ('00000000-0000-0000-0000-0000000000aa', 'BY')
on conflict (id) do update set country_code = 'BY';

-- Симулируем авторизованного пользователя (auth.uid()).
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"00000000-0000-0000-0000-0000000000aa","role":"authenticated"}';

-- Чек в статусе review с «черновыми» позициями (как от воркера).
-- Вставляем через service-role-подобный путь: временно вернёмся к postgres-роли,
-- т.к. клиент чек в review не создаёт — это делает воркер.
reset role;
insert into public.receipts (id, user_id, country_code, source, status, total)
values ('00000000-0000-0000-0000-0000000000b1',
        '00000000-0000-0000-0000-0000000000aa', 'BY', 'ocr', 'review', 99.99);
insert into public.receipt_items (receipt_id, user_id, raw_name, qty, unit_price, sum)
values ('00000000-0000-0000-0000-0000000000b1',
        '00000000-0000-0000-0000-0000000000aa', 'СТАРОЕ', 1, 99.99, 99.99);

-- Снова как пользователь.
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"00000000-0000-0000-0000-0000000000aa","role":"authenticated"}';

-- HAPPY PATH: подтверждаем с правленными позициями.
select public.confirm_receipt(
  '00000000-0000-0000-0000-0000000000b1',
  '[{"raw_name":"Молоко","qty":1,"unit_price":2.50,"sum":2.50},
    {"raw_name":"Хлеб","qty":2,"unit_price":1.25,"sum":2.50}]'::jsonb
);

-- Проверки happy path.
do $$
declare r public.receipts; n int; s numeric;
begin
  select * into r from public.receipts where id = '00000000-0000-0000-0000-0000000000b1';
  assert r.status = 'done', 'status must be done, got ' || r.status;
  assert r.total = 5.00, 'total must be 5.00 (recomputed), got ' || r.total;
  select count(*), coalesce(sum(sum),0) into n, s
    from public.receipt_items where receipt_id = '00000000-0000-0000-0000-0000000000b1';
  assert n = 2, '2 items expected, got ' || n;
  assert s = 5.00, 'items sum 5.00 expected, got ' || s;
  assert not exists (select 1 from public.receipt_items
                     where receipt_id = '00000000-0000-0000-0000-0000000000b1'
                       and raw_name = 'СТАРОЕ'), 'old item must be replaced';
end $$;

-- ОТКАЗ 1: повторное подтверждение (статус уже done, не review) → исключение.
do $$
begin
  perform public.confirm_receipt('00000000-0000-0000-0000-0000000000b1', '[]'::jsonb);
  raise exception 'TEST FAILED: expected status-gate rejection';
exception
  when sqlstate '22023' then null; -- ожидаемо: not in review
end $$;

-- ОТКАЗ 2: чужой чек (другой uid) → исключение 42501.
-- ВАЖНО: на receipts висит BEFORE INSERT триггер receipts_fill_owner, который
-- безусловно ставит user_id = auth.uid() из активного JWT-claim (claim живёт всю
-- транзакцию, reset role его не сбрасывает). Чтобы чек реально принадлежал cc,
-- на время вставки выставляем sub = cc, затем возвращаем sub = aa перед вызовом RPC.
reset role;
insert into auth.users (id, email)
values ('00000000-0000-0000-0000-0000000000cc', 'other@example.com');
insert into public.profiles (id, country_code)
values ('00000000-0000-0000-0000-0000000000cc', 'BY') on conflict (id) do nothing;
set local request.jwt.claims =
  '{"sub":"00000000-0000-0000-0000-0000000000cc","role":"authenticated"}';
insert into public.receipts (id, country_code, source, status)
values ('00000000-0000-0000-0000-0000000000b2', 'BY', 'ocr', 'review');
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"00000000-0000-0000-0000-0000000000aa","role":"authenticated"}';
do $$
begin
  perform public.confirm_receipt('00000000-0000-0000-0000-0000000000b2', '[]'::jsonb);
  raise exception 'TEST FAILED: expected ownership rejection';
exception
  when sqlstate '42501' then null; -- ожидаемо: not owned
end $$;

select 'ALL ASSERTIONS PASSED' as result;
rollback;
