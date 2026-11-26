-- Hachibu — Açık rıza kaydı (KVKK m.6/2, sağlık verisi)
--
-- Çalıştırma: store_feature_lockdown.sql'den SONRA, SQL Editor'de bir kez. İdempotent.
--
-- Rıza profiles tablosunda tutulur: ne zaman verildiği + hangi metin sürümüne
-- verildiği. Metin sürümü değişirse (legal/*.md "Sürüm" satırı) uygulama
-- consent_version'ı karşılaştırıp yeniden onay ister.

alter table public.profiles add column if not exists consent_at      timestamptz;
alter table public.profiles add column if not exists consent_version text;

alter table public.profiles drop constraint if exists profiles_consent_version_len;
alter table public.profiles add constraint profiles_consent_version_len
  check (consent_version is null or char_length(consent_version) <= 20) not valid;

-- Kullanıcı kendi satırında yalnızca consent_version'ı (ve mevcut locale,
-- full_name) güncelleyebilir. consent_at'e yazma yetkisi YOK — onu aşağıdaki
-- trigger sunucu saatiyle doldurur. role hâlâ yazılamaz.
revoke update on public.profiles from authenticated;
grant  update (locale, full_name, consent_version)
  on public.profiles to authenticated;

-- consent_at'i istemcinin saatine bırakmamak için: her güncellemede sunucu
-- saatiyle damgalanır (istemcinin gönderdiği değer yok sayılır).
create or replace function public.stamp_consent_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.consent_version is distinct from old.consent_version then
    new.consent_at := case when new.consent_version is null then null else now() end;
  else
    new.consent_at := old.consent_at;  -- istemci consent_at'i tek başına değiştiremez
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_stamp_consent on public.profiles;
create trigger profiles_stamp_consent
  before update on public.profiles
  for each row execute function public.stamp_consent_at();

-- Doğrulama: beklenen = consent_version, full_name, locale
select column_name
from information_schema.column_privileges
where table_schema = 'public' and table_name = 'profiles'
  and grantee = 'authenticated' and privilege_type = 'UPDATE'
order by 1;
