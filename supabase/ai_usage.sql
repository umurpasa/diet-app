-- Diyet Uygulaması — AI kullanım limiti (günlük)
-- Çalıştırma: schema.sql + policies.sql'den SONRA, SQL Editor'de çalıştır.
-- Amaç: Gemini maliyetini kontrol etmek için kullanıcı başına GÜNLÜK AI çağrı limiti.
-- Sayaç Edge Function tarafından atomik olarak artırılır (SECURITY DEFINER RPC).

-- 1) Kullanım sayacı: kullanıcı-gün başına tek satır
create table if not exists public.ai_usage (
  user_id     uuid not null references public.profiles(id) on delete cascade,
  usage_date  date not null default current_date,
  count       int  not null default 0,
  primary key (user_id, usage_date)
);

alter table public.ai_usage enable row level security;

-- Kullanıcı yalnızca kendi kullanım sayısını GÖREBİLİR (kota göstergesi için).
-- Yazma sadece aşağıdaki SECURITY DEFINER fonksiyonu üzerinden yapılır.
drop policy if exists ai_usage_own_select on public.ai_usage;
create policy ai_usage_own_select on public.ai_usage
  for select to authenticated using (user_id = auth.uid());

-- 2) Atomik "limit kontrol + artır" fonksiyonu.
--    p_limit'e ULAŞILMAMIŞSA sayacı 1 artırır ve true döner.
--    Limit dolmuşsa hiçbir şey yazmaz ve false döner.
--    Tek INSERT ... ON CONFLICT ile yarış koşulu (race) olmadan çalışır.
create or replace function public.check_and_increment_ai_usage(p_limit int)
returns boolean
language plpgsql
security definer set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_count int;
begin
  if v_user is null then
    return false; -- oturum yok
  end if;

  insert into public.ai_usage (user_id, usage_date, count)
  values (v_user, current_date, 1)
  on conflict (user_id, usage_date)
    do update set count = public.ai_usage.count + 1
    where public.ai_usage.count < p_limit
  returning count into v_count;

  -- Çakışmada WHERE eşleşmediyse (limit dolu) hiçbir satır dönmez → v_count null.
  return v_count is not null;
end;
$$;

grant execute on function public.check_and_increment_ai_usage(int) to authenticated;
