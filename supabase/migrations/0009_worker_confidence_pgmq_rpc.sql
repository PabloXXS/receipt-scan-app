-- Миграция: worker — confidence на позициях + public RPC-обёртки pgmq (service_role).
-- Зона доступа: A (receipt_items). pgmq-обёртки — служебные, только service_role.
-- Инвариант приватности: зона A/служебная очередь; в зону C ничего не уходит.

-- 1. Уверенность распознавания позиции (для подсветки в ревью на клиенте).
alter table public.receipt_items
  add column if not exists confidence numeric(4, 3);

-- 2. RPC-обёртки pgmq для воркера (PostgREST не отдаёт схему pgmq напрямую).
--    Доступ строго service_role; revoke с anon/authenticated.

create or replace function public.pgmq_read_jobs(
  p_queue text,
  p_vt integer,
  p_qty integer
)
returns table (msg_id bigint, read_ct integer, message jsonb)
language sql
security definer
set search_path = pgmq, public, pg_temp
as $$
  select msg_id, read_ct, message
  from pgmq.read(p_queue, p_vt, p_qty);
$$;

create or replace function public.pgmq_delete_job(p_queue text, p_msg_id bigint)
returns boolean
language sql
security definer
set search_path = pgmq, public, pg_temp
as $$
  select pgmq.delete(p_queue, p_msg_id);
$$;

create or replace function public.pgmq_archive_job(p_queue text, p_msg_id bigint)
returns boolean
language sql
security definer
set search_path = pgmq, public, pg_temp
as $$
  select pgmq.archive(p_queue, p_msg_id);
$$;

revoke execute on function public.pgmq_read_jobs(text, integer, integer) from public, anon, authenticated;
revoke execute on function public.pgmq_delete_job(text, bigint) from public, anon, authenticated;
revoke execute on function public.pgmq_archive_job(text, bigint) from public, anon, authenticated;
grant execute on function public.pgmq_read_jobs(text, integer, integer) to service_role;
grant execute on function public.pgmq_delete_job(text, bigint) to service_role;
grant execute on function public.pgmq_archive_job(text, bigint) to service_role;
