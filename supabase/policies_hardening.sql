-- Diyet Uygulaması — RLS sertleştirme (güvenlik denetimi sonrası)
--
-- Çalıştırma: schema.sql + policies.sql + ai_usage.sql + emergency_logs.sql'den
-- SONRA, Supabase paneli > SQL Editor'de bir kez çalıştır.
--
-- Gerekçe: Repo herkese açık hale geldiğinde şema ve politikalar da görünür olur.
-- Anon key zaten tasarım gereği istemcide taşınır (yetkisi yoktur, yetkiyi RLS
-- verir) — bu yüzden güvenlik sınırı tamamen bu dosyada tanımlanan kurallardır.
--
-- Bu dosya idempotenttir: birden fazla kez çalıştırılabilir.

-- ============================================================
-- 1) YETKİ YÜKSELTME — profiles.role kullanıcı tarafından değiştirilemez
-- ============================================================
-- Sorun: policies.sql'deki `profiles_own_update` politikası satır bazında doğru
-- (kullanıcı yalnızca kendi satırını günceller) ama KOLON bazında sınır yok.
-- Kullanıcı kendi satırında `role = 'dietitian'` yazabilirdi.
--
-- RLS politikaları kolon bazında kısıt koyamaz; doğru araç kolon seviyesinde
-- GRANT. Aşağıda kullanıcıya yalnızca kendi değiştirebileceği alanlar bırakılır.
revoke update on public.profiles from authenticated;
grant  update (locale, full_name) on public.profiles to authenticated;

-- ============================================================
-- 2) DİYETİSYEN KİMLİĞİ — kullanıcı kendini diyetisyen olarak kaydedemez
-- ============================================================
-- Sorun: `dietitians_own_all` politikası FOR ALL olduğu için INSERT'i de
-- kapsıyordu; herhangi bir kullanıcı `dietitians` tablosuna kendi user_id'siyle
-- satır ekleyip diyetisyen listesinde görünebilirdi.
--
-- Diyetisyen kaydı bir doğrulama sürecidir; istemciden açılmaz. Satır
-- oluşturma sunucu tarafında (service_role, RLS'i bypass eder) yapılır.
-- Diyetisyen yalnızca kendi bio/uzmanlık alanlarını güncelleyebilir.
drop policy if exists dietitians_own_all on public.dietitians;

create policy dietitians_own_update on public.dietitians
  for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- (dietitians_public_select politikası korunuyor: giriş yapmış herkes
--  diyetisyen profillerini görebilir — diyetisyen seçimi için gerekli,
--  bilinçli bir açıklıktır. Bu tabloya kişisel/hassas veri KONMAMALI.)

-- ============================================================
-- 3) MESAJLAŞMA — yalnızca eşleşmiş kullanıcı/diyetisyen çiftleri
-- ============================================================
-- Sorun: `messages_send` politikası yalnızca `sender_id = auth.uid()` kontrol
-- ediyordu; receiver_id serbestti. Yani herhangi bir kullanıcı, herhangi bir
-- başka kullanıcıya mesaj gönderebilirdi (spam/taciz vektörü).
--
-- Çözüm: gönderim, aktif bir atama (assignments) ile bağlı çiftlere kısıtlanır.
create or replace function public.is_paired_with(other uuid)
returns boolean
language sql
stable
security definer set search_path = public
as $$
  select exists (
    select 1 from public.assignments a
    where a.active
      and (
        (a.user_id = auth.uid()      and a.dietitian_id = other) or
        (a.dietitian_id = auth.uid() and a.user_id      = other)
      )
  );
$$;

grant execute on function public.is_paired_with(uuid) to authenticated;

drop policy if exists messages_send on public.messages;
create policy messages_send on public.messages
  for insert to authenticated
  with check (sender_id = auth.uid() and public.is_paired_with(receiver_id));

-- ============================================================
-- 4) MESAJ BÜTÜNLÜĞÜ — alıcı mesajın içeriğini değiştiremez
-- ============================================================
-- Sorun: `messages_mark_read` politikası alıcıya satırın TAMAMI üzerinde UPDATE
-- veriyordu. Amaç yalnızca `read_at` işaretlemekti, ama alıcı `body` alanını da
-- yeniden yazabilir — yani karşı tarafın gönderdiği mesajı değiştirebilirdi.
--
-- Çözüm: kolon seviyesinde GRANT ile yalnızca read_at güncellenebilir.
revoke update on public.messages from authenticated;
grant  update (read_at) on public.messages to authenticated;

-- ============================================================
-- 5) PLAN KAYNAĞI — kullanıcı planı "diyetisyen üretimi" gibi gösteremez
-- ============================================================
-- Sorun: `plans_own_all` FOR ALL olduğundan kullanıcı kendi satırına
-- `generated_by = 'dietitian'` yazabilirdi. Uygulama bu alana göre "planını
-- diyetisyenin hazırladı" etiketi gösteriyor → yanıltıcı veri.
drop policy if exists plans_own_all on public.diet_plans;

create policy plans_own_select on public.diet_plans
  for select to authenticated using (user_id = auth.uid());
create policy plans_own_insert on public.diet_plans
  for insert to authenticated
  with check (user_id = auth.uid() and generated_by = 'ai');
create policy plans_own_update on public.diet_plans
  for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy plans_own_delete on public.diet_plans
  for delete to authenticated using (user_id = auth.uid());

-- ============================================================
-- 6) KVKK — kullanıcı kendi acil kayıtlarını silebilmeli
-- ============================================================
-- emergency_logs.sql yalnızca insert + select politikası tanımlamıştı; kullanıcı
-- kendi ürettiği veriyi silemiyordu. Veri sahibinin silme hakkı (KVKK m.7 /
-- GDPR "right to erasure") teknik olarak da karşılanmalı.
drop policy if exists emergency_own_delete on public.emergency_logs;
create policy emergency_own_delete on public.emergency_logs
  for delete to authenticated using (user_id = auth.uid());

-- ============================================================
-- 7) DOĞRULAMA — çalıştırdıktan sonra bunları kontrol et
-- ============================================================
-- (a) RLS'siz veya politikasız public tablo kalmamalı:
--
--   select c.relname,
--          c.relrowsecurity  as rls_acik,
--          count(p.polname)  as politika_sayisi
--   from pg_class c
--   join pg_namespace n on n.oid = c.relnamespace
--   left join pg_policy p on p.polrelid = c.oid
--   where n.nspname = 'public' and c.relkind = 'r'
--   group by 1,2 order by 1;
--
-- (b) profiles.role artık authenticated tarafından yazılamamalı:
--
--   select column_name, privilege_type
--   from information_schema.column_privileges
--   where table_name = 'profiles' and grantee = 'authenticated'
--     and privilege_type = 'UPDATE';
--   -- Beklenen: yalnızca locale ve full_name
