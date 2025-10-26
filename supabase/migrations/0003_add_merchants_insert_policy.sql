-- Добавляем политику для создания магазинов
-- Любой аутентифицированный пользователь может создавать магазины

create policy "Users can create merchants" on merchants
  for insert to authenticated
  with check (true);

-- Также добавляем политику для обновления магазинов
create policy "Users can update merchants" on merchants
  for update to authenticated
  using (true)
  with check (true);

-- Добавляем политику для удаления магазинов (мягкое удаление)
create policy "Users can delete merchants" on merchants
  for update to authenticated
  using (true)
  with check (true);
