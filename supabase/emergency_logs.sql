-- Acil Buton v1 — emergency_logs tablosu + RLS
--
-- NOT: Bu dosya otomatik çalıştırılmaz. Supabase Dashboard > SQL Editor'de
-- MANUEL çalıştır (schema.sql ve policies.sql'den sonra, bir kez).
--
-- Uygulamanın yazdığı değerler (lib/pages/emergency_page.dart):
--   trigger_type: night_snacking | sweet_craving | hunger_between_meals | stress_eating
--   outcome:      overcame (krizi atlattım) | ate_anyway (yine de yedim)

create table if not exists public.emergency_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  trigger_type text,
  outcome text,
  created_at timestamptz default now()
);

alter table public.emergency_logs enable row level security;

-- Diğer tablolardaki own_all deseninin insert/select alt kümesi:
-- kullanıcı yalnızca kendi satırlarını ekleyip görebilir.
create policy emergency_own_insert on public.emergency_logs
  for insert to authenticated with check (user_id = auth.uid());

create policy emergency_own_select on public.emergency_logs
  for select to authenticated using (user_id = auth.uid());
