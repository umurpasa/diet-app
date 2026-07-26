-- Diyet Uygulaması — RLS politikaları + yardımcılar
-- Çalıştırma: schema.sql'den SONRA, SQL Editor'de çalıştır.

-- ============================================================
-- 1) Yeni auth kullanıcısı için otomatik profiles satırı
-- ============================================================
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id) values (new.id)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============================================================
-- 2) Yardımcı: giriş yapan kişi, hedef kullanıcının aktif diyetisyeni mi?
--    SECURITY DEFINER => RLS'i bypass eder, döngü/recursion olmaz.
-- ============================================================
create or replace function public.is_dietitian_of(target uuid)
returns boolean
language sql
stable
security definer set search_path = public
as $$
  select exists (
    select 1 from public.assignments a
    where a.dietitian_id = auth.uid()
      and a.user_id = target
      and a.active
  );
$$;

grant execute on function public.is_dietitian_of(uuid) to authenticated;

-- ============================================================
-- 3) Politikalar (hepsi 'authenticated' rolü için)
-- ============================================================

-- profiles
create policy profiles_own_select on public.profiles
  for select to authenticated using (id = auth.uid());
create policy profiles_own_update on public.profiles
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());
create policy profiles_dietitian_select on public.profiles
  for select to authenticated using (public.is_dietitian_of(id));
create policy profiles_view_dietitians on public.profiles
  for select to authenticated using (role = 'dietitian');

-- health_profiles
create policy health_own_all on public.health_profiles
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy health_dietitian_select on public.health_profiles
  for select to authenticated using (public.is_dietitian_of(user_id));

-- diet_plans
create policy plans_own_all on public.diet_plans
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy plans_dietitian_select on public.diet_plans
  for select to authenticated using (public.is_dietitian_of(user_id));
create policy plans_dietitian_insert on public.diet_plans
  for insert to authenticated with check (public.is_dietitian_of(user_id));

-- food_logs
create policy food_own_all on public.food_logs
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy food_dietitian_select on public.food_logs
  for select to authenticated using (public.is_dietitian_of(user_id));

-- water_logs
create policy water_own_all on public.water_logs
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy water_dietitian_select on public.water_logs
  for select to authenticated using (public.is_dietitian_of(user_id));

-- progress
create policy progress_own_all on public.progress
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy progress_dietitian_select on public.progress
  for select to authenticated using (public.is_dietitian_of(user_id));

-- dietitians (kendi satırını yönetir; herkes diyetisyen profillerini görebilir)
create policy dietitians_own_all on public.dietitians
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy dietitians_public_select on public.dietitians
  for select to authenticated using (true);

-- assignments (kullanıcı kendi atamalarını, diyetisyen kendine ait atamaları görür;
--   atama oluşturma sunucu tarafında service_role ile yapılır, o RLS'i bypass eder)
create policy assignments_user_select on public.assignments
  for select to authenticated using (user_id = auth.uid());
create policy assignments_dietitian_select on public.assignments
  for select to authenticated using (dietitian_id = auth.uid());

-- messages (sadece gönderen/alan görür; gönderen yazar; alan okundu işaretler)
create policy messages_participant_select on public.messages
  for select to authenticated using (sender_id = auth.uid() or receiver_id = auth.uid());
create policy messages_send on public.messages
  for insert to authenticated with check (sender_id = auth.uid());
create policy messages_mark_read on public.messages
  for update to authenticated using (receiver_id = auth.uid()) with check (receiver_id = auth.uid());

-- ai_chats
create policy ai_chats_own_all on public.ai_chats
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
