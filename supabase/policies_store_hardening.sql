-- Diyet Uygulaması — Store öncesi sertleştirme (güvenlik denetimi, Kasım 2026)
--
-- Çalıştırma: policies_hardening.sql'den SONRA, Supabase paneli > SQL Editor'de
-- bir kez çalıştır. İdempotenttir (tekrar çalıştırılabilir).
--
-- Tehdit modeli: Kayıt herkese açık ve anon key public. "Hesap açmış bir yabancı
-- uygulamayı atlayıp REST API'yi doğrudan çağırırsa ne yapabilir?" sorusuna göre.

-- ============================================================
-- 1) PLAN KAYNAĞI — UPDATE ile "diyetisyen üretimi" sahteciliği
-- ============================================================
-- Sorun: policies_hardening.sql #5 INSERT'te generated_by = 'ai' zorunlu kıldı,
-- ama plans_own_update kolon sınırı koymuyor. Kullanıcı önce 'ai' olarak ekleyip
-- sonra UPDATE ile generated_by = 'dietitian' yapabilir → aynı açık geri geliyor.
--
-- Çözüm: istemci diet_plans'ı hiç güncellemiyor; tek güncelleyen Edge Function
-- (eski planı pasifleştirmek için is_active). Kolon seviyesinde yalnızca o kalır.
revoke update on public.diet_plans from authenticated;
grant  update (is_active) on public.diet_plans to authenticated;

-- ============================================================
-- 2) BOYUT / DEĞER SINIRLARI — veritabanını doldurma saldırısı
-- ============================================================
-- Sorun: Metin/jsonb alanlarında uzunluk sınırı yok. Bir kullanıcı API'den
-- megabaytlarca metin yazarak ücretsiz plandaki veritabanı kotasını doldurabilir;
-- kota dolunca proje salt-okunur olur ve uygulama HERKES için bozulur.
--
-- NOT VALID: mevcut satırlar kontrol edilmez, yalnızca yeni yazılanlar.
-- Sınırlar bilinçli olarak geniş tutuldu; normal kullanımı etkilemez.

-- Metin uzunlukları
alter table public.profiles drop constraint if exists profiles_full_name_len;
alter table public.profiles add constraint profiles_full_name_len
  check (full_name is null or char_length(full_name) <= 100) not valid;

alter table public.health_profiles drop constraint if exists hp_text_len;
alter table public.health_profiles add constraint hp_text_len
  check (
    (goal is null           or char_length(goal) <= 500) and
    (health_history is null or char_length(health_history) <= 2000) and
    (allergies is null      or char_length(allergies) <= 1000)
  ) not valid;

alter table public.health_profiles drop constraint if exists hp_prefs_size;
alter table public.health_profiles add constraint hp_prefs_size
  check (preferences is null or pg_column_size(preferences) <= 8192) not valid;

alter table public.food_logs drop constraint if exists food_name_len;
alter table public.food_logs add constraint food_name_len
  check (char_length(name) <= 200 and (meal_type is null or char_length(meal_type) <= 30)) not valid;

alter table public.progress drop constraint if exists progress_meas_size;
alter table public.progress add constraint progress_meas_size
  check (measurements is null or pg_column_size(measurements) <= 4096) not valid;

alter table public.diet_plans drop constraint if exists plans_size;
alter table public.diet_plans add constraint plans_size
  check (
    char_length(content) <= 20000 and
    (plan_json is null or pg_column_size(plan_json) <= 65536)
  ) not valid;

alter table public.messages drop constraint if exists messages_body_len;
alter table public.messages add constraint messages_body_len
  check (char_length(body) <= 4000) not valid;

alter table public.dietitians drop constraint if exists dietitians_bio_len;
alter table public.dietitians add constraint dietitians_bio_len
  check (bio is null or char_length(bio) <= 2000) not valid;

alter table public.emergency_logs drop constraint if exists emergency_text_len;
alter table public.emergency_logs add constraint emergency_text_len
  check (
    (trigger_type is null or char_length(trigger_type) <= 50) and
    (outcome is null      or char_length(outcome) <= 50)
  ) not valid;

-- Sayısal makullük (saçma değerler grafikleri/hesapları bozmasın)
alter table public.health_profiles drop constraint if exists hp_numeric_range;
alter table public.health_profiles add constraint hp_numeric_range
  check (
    (age is null       or age between 10 and 120) and
    (height_cm is null or height_cm between 50 and 260) and
    (weight_kg is null or weight_kg between 20 and 400)
  ) not valid;

alter table public.progress drop constraint if exists progress_weight_range;
alter table public.progress add constraint progress_weight_range
  check (weight_kg is null or weight_kg between 20 and 400) not valid;

alter table public.food_logs drop constraint if exists food_calories_range;
alter table public.food_logs add constraint food_calories_range
  check (calories is null or calories between 0 and 10000) not valid;

alter table public.water_logs drop constraint if exists water_glasses_range;
alter table public.water_logs add constraint water_glasses_range
  check (glasses between 0 and 50) not valid;
