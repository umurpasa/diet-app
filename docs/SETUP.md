# Kurulum

Projeyi sıfırdan çalışır hale getirmek için gereken adımlar. Mimari kararlar
için [ARCHITECTURE.md](ARCHITECTURE.md).

## Gereksinimler

- Flutter SDK (Dart `^3.6.1`)
- Bir Supabase projesi (ücretsiz plan yeterli)
- Bir Google AI Studio API anahtarı (Gemini)
- Supabase CLI — Edge Function deploy'u için

## 1. Veritabanı

Supabase paneli > **SQL Editor**'de dosyaları **bu sırayla** çalıştır:

| Sıra | Dosya | İçerik |
|---|---|---|
| 1 | `supabase/schema.sql` | 10 tablo, indeksler, tüm tablolarda RLS açık |
| 2 | `supabase/policies.sql` | Erişim politikaları, `handle_new_user` trigger'ı, `is_dietitian_of()` |
| 3 | `supabase/ai_usage.sql` | Günlük AI kotası tablosu + atomik sayaç RPC'si |
| 4 | `supabase/plan_json.sql` | `diet_plans.plan_json` kolonu |
| 5 | `supabase/emergency_logs.sql` | Acil buton kayıt tablosu |
| 6 | `supabase/policies_hardening.sql` | Güvenlik denetimi sonrası sertleştirmeler |

6. adım **atlanmamalı** — yetki yükseltme ve mesaj bütünlüğü açıklarını o dosya
kapatıyor; gerekçeler dosyanın içinde yorum olarak duruyor.

Mesajlaşmanın anlık çalışması için Realtime yayınını aç:

```sql
alter publication supabase_realtime add table public.messages;
```

## 2. Uygulama bağlantısı

`lib/config/supabase_config.dart` içindeki `url` ve `anonKey` değerlerini kendi
projeninkilerle değiştir (Supabase paneli > Project Settings > API).

Anon key istemcide bulunmak üzere tasarlanmıştır ve tek başına yetki taşımaz;
erişim sınırını RLS çizer. `service_role` anahtarı **hiçbir koşulda** uygulama
koduna girmez.

```bash
flutter pub get
flutter gen-l10n
flutter run
```

## 3. AI katmanı (Edge Function)

Gemini anahtarını al (https://aistudio.google.com/apikey). Bu anahtar yalnızca
Supabase secret olarak kullanılır, koda yazılmaz.

Supabase CLI'ı kur — `npm install -g supabase` **desteklenmiyor**:

```powershell
# Windows / Scoop
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase
```

```bash
# ya da global kurulum olmadan
npm install supabase --save-dev   # komutların başına: npx supabase ...
```

Bağlan, secret'ı ekle, deploy et:

```bash
supabase login
supabase link --project-ref <PROJE_REF>

supabase secrets set GEMINI_API_KEY=<anahtarın>
# opsiyonel:
# supabase secrets set GEMINI_MODEL=gemini-3.5-flash
# supabase secrets set AI_DAILY_LIMIT=20

supabase functions deploy ai
```

`SUPABASE_URL` ve `SUPABASE_ANON_KEY` Edge Function ortamına otomatik enjekte
edilir, ayrıca tanımlamaya gerek yok.

## 4. Diyetisyen hesabı (opsiyonel — mesajlaşmayı denemek için)

Diyetisyen kaydı ve atama uygulama içinden yapılmıyor; doğrulama gerektiren bir
süreç olduğu için sunucu tarafında oluşturuluyor. Denemek istersen ikinci bir
hesap açıp SQL Editor'de (postgres rolüyle çalışır, RLS'i bypass eder):

```sql
-- rolü diyetisyen yap
update public.profiles
set role = 'dietitian', full_name = 'Demo Diyetisyen'
where id = (select id from auth.users where email = '<diyetisyen_eposta>');

-- vitrin satırı
insert into public.dietitians (user_id, bio, specialties)
values (
  (select id from auth.users where email = '<diyetisyen_eposta>'),
  'Demo diyetisyen — test hesabı.',
  array['kilo yönetimi']
)
on conflict (user_id) do nothing;

-- kullanıcı ↔ diyetisyen ataması
insert into public.assignments (user_id, dietitian_id, package, active)
values (
  (select id from auth.users where email = '<kullanici_eposta>'),
  (select id from auth.users where email = '<diyetisyen_eposta>'),
  'demo', true
);
```

Atama olmadan mesajlaşma çalışmaz — bu kasıtlıdır, `messages` politikası
gönderimi yalnızca eşleşmiş çiftlere izin verir.

## Sorun giderme

| Belirti | Sebep | Çözüm |
|---|---|---|
| `401 Oturum doğrulanamadı` | Edge Function JWT bekliyor | Uygulamada giriş yap |
| `500 Sunucu yapılandırması eksik` | `GEMINI_API_KEY` secret'ı yok | 3. adımı tekrarla, sonra yeniden deploy et |
| Gemini 404 (model bulunamadı) | Model adı geçersiz/emekli | `supabase secrets set GEMINI_MODEL=...` |
| Plan hep aynı geliyor | Aktif plan önbellekten dönüyor | "Yeniden oluştur" düğmesi |
| Mesajlar gecikmeli düşüyor | Realtime yayını kapalı | 1. adımdaki `alter publication` |
| "Henüz diyetisyen atanmadı" | Aktif `assignments` satırı yok | 4. adım |
