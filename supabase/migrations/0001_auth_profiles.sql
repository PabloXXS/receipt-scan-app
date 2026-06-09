-- Миграция: auth — таблица profiles (зона A) + автосоздание профиля при регистрации.
-- Зона доступа: A (приватные данные пользователя; RLS по auth.uid() = id).
-- Инвариант приватности: таблица зоны A, user-данные; в зону C ничего не уходит.

create table if not exists public.profiles (
  id           uuid primary key references auth.users (id) on delete cascade,
  country_code text not null,
  display_name text,
  family_id    uuid,
  settings     jsonb not null default '{}'::jsonb,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- Зона A: пользователь видит и меняет только свой профиль.
create policy "profiles_select_own"
  on public.profiles for select
  using (auth.uid() = id);

create policy "profiles_insert_own"
  on public.profiles for insert
  with check (auth.uid() = id);

create policy "profiles_update_own"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Универсальный триггер обновления updated_at.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- Автосоздание профиля при регистрации.
-- country_code/display_name берутся из user_metadata (передаются клиентом при signUp).
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  insert into public.profiles (id, country_code, display_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'country_code', ''),
    new.raw_user_meta_data ->> 'display_name'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
