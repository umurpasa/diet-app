-- Diyet Uygulaması — Store sürümü: AI ve diyetisyen özelliklerini SUNUCUDA kapatma
--
-- Çalıştırma: policies_store_hardening.sql'den SONRA, SQL Editor'de bir kez.
-- İdempotenttir.
--
-- Neden sunucuda? Kayıt herkese açık ve anon key public; arayüzde "not active"
-- yazmak, API'yi doğrudan çağıran birini durdurmaz. Kapatma veritabanı yetkisi
-- seviyesinde yapılır.
--
-- Yöntem: Politikalar SİLİNMEZ, yalnızca yazma yetkileri (GRANT) geri alınır.
-- Böylece özellik ileride açılmak istenirse en alttaki "YENİDEN AÇMA" bloğu
-- çalıştırılır; tasarım/RLS mantığı repoda olduğu gibi kalır.

-- ============================================================
-- 1) AI — sohbet, plan üretimi, kullanım sayacı
-- ============================================================
-- Edge Function ayrıca panelden silinir (bkz. talimatlar); bu blok,
-- fonksiyon olmasa bile istemcinin AI tablolarına yazamamasını garanti eder.
revoke insert, update on public.ai_chats  from authenticated;
revoke insert, update on public.diet_plans from authenticated;
revoke execute on function public.check_and_increment_ai_usage(int)
  from public, anon, authenticated;

-- ============================================================
-- 2) Diyetisyen — mesajlaşma ve diyetisyen profili
-- ============================================================
revoke insert, update on public.messages   from authenticated;
revoke update         on public.dietitians from authenticated;

-- ============================================================
-- 3) Demo verilerini temizle
-- ============================================================
-- Demo diyetisyen kurulumu (docs/DEMO_DIETITIAN.md) ile oluşan satırlar.
-- Demo diyetisyenin auth hesabı ayrıca panelden silinir (bkz. talimatlar).
delete from public.messages;
delete from public.assignments;
delete from public.dietitians;
update public.profiles set role = 'user' where role = 'dietitian';

-- ============================================================
-- 4) DOĞRULAMA — authenticated rolünün kalan yazma yetkileri
-- ============================================================
-- Beklenen: ai_chats / messages / dietitians / diet_plans için INSERT/UPDATE
-- satırı YOK (diet_plans'ta yalnızca DELETE kalabilir).
select table_name, privilege_type
from information_schema.role_table_grants
where grantee = 'authenticated'
  and table_schema = 'public'
  and table_name in ('ai_chats','messages','dietitians','diet_plans')
  and privilege_type in ('INSERT','UPDATE')
union all
select table_name, 'UPDATE(' || column_name || ')'
from information_schema.column_privileges
where grantee = 'authenticated'
  and table_schema = 'public'
  and table_name in ('ai_chats','messages','dietitians','diet_plans')
  and privilege_type = 'UPDATE';

-- ============================================================
-- YENİDEN AÇMA (şimdi ÇALIŞTIRMA — ileride özellik açılırsa)
-- ============================================================
-- grant insert on public.ai_chats to authenticated;
-- grant insert on public.diet_plans to authenticated;
-- grant update (is_active) on public.diet_plans to authenticated;
-- grant execute on function public.check_and_increment_ai_usage(int) to authenticated;
-- grant insert on public.messages to authenticated;
-- grant update (read_at) on public.messages to authenticated;
-- grant update on public.dietitians to authenticated;
-- (+ Edge Function'ı yeniden deploy et, GEMINI_API_KEY secret'ını ekle)
