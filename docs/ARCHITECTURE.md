# Mimari

Bu doküman uygulamanın nasıl kurgulandığını ve neden bu şekilde kurgulandığını
anlatır. Kurulum adımları için [SETUP.md](SETUP.md).

## 1. Genel bakış

```
┌─────────────────────────────┐
│  Flutter (iOS / Android)    │
│  · UI + durum yönetimi      │
│  · yalnızca anon key taşır  │
└──────────────┬──────────────┘
               │ kullanıcı JWT'si
       ┌───────┴────────┐
       ▼                ▼
┌─────────────┐   ┌──────────────────────┐
│  Supabase   │   │  Edge Function "ai"  │
│  Postgres   │◄──┤  (Deno)              │
│  + RLS      │   │  · GEMINI_API_KEY    │
│  + Auth     │   │    yalnızca burada   │
│  + Realtime │   └──────────┬───────────┘
└─────────────┘              ▼
                       ┌───────────┐
                       │  Gemini   │
                       └───────────┘
```

İstemci Postgres'e doğrudan konuşur; erişim sınırını Row Level Security çizer.
Maliyet doğuran veya sır gerektiren her şey Edge Function'ın arkasındadır.

## 2. Güvenlik modeli

Bu projedeki en bilinçli tasarım kararları burada.

**İstemcide sır yoktur.** `lib/config/supabase_config.dart` içindeki anon key
bir yetki taşımaz — içeriği yalnızca `"role": "anon"` olan bir JWT'dir ve zaten
her Supabase istemcisinde bulunması beklenir (derlenmiş bir APK'dan da okunabilir).
Yetkiyi RLS politikaları verir. Gemini API anahtarı istemciye hiç inmez; Supabase
secret olarak yalnızca Edge Function ortamında bulunur.

**Varsayılan kapalıdır.** `schema.sql` tüm tablolarda RLS'i politika tanımlamadan
önce açar. Politikasız tablo = erişimi tamamen kapalı tablo. Yeni bir tablo
eklendiğinde unutulursa sonuç "herkese açık" değil "kimseye kapalı" olur.

**Hassas veri ayrı tablodadır.** Yaş, kilo, sağlık geçmişi ve alerjiler
`profiles` içinde değil, ayrı `health_profiles` tablosundadır. Böylece
diyetisyenin kullanıcı adını görmesi ile sağlık geçmişini görmesi iki ayrı
politika kararıdır; biri diğerini otomatik açmaz (KVKK'daki özel nitelikli
kişisel veri ayrımı).

**Diyetisyen erişimi bir fonksiyonla belirlenir.** `is_dietitian_of(target)`
fonksiyonu `SECURITY DEFINER`'dır ve `assignments` tablosuna RLS'i bypass ederek
bakar. Bu bilinçlidir: politika içinden RLS korumalı bir tabloyu sorgulamak
sonsuz özyinelemeye yol açar. Aynı desen mesajlaşmadaki `is_paired_with()` için
de kullanılır.

**Yetki yükseltme kapatılmıştır.** RLS politikaları satır bazında çalışır, kolon
bazında değil. `policies_hardening.sql` kolon seviyesinde `GRANT` kullanarak
kullanıcının kendi `profiles.role` alanını `dietitian` yapmasını ve bir mesajın
alıcısının `body` alanını yeniden yazmasını engeller. Denetim sırasında bulunan
bulguların tamamı ve gerekçeleri o dosyanın yorumlarındadır.

**AI maliyeti veritabanında sınırlanır.** `check_and_increment_ai_usage(p_limit)`
tek bir `INSERT ... ON CONFLICT ... WHERE count < limit` ifadesiyle limit
kontrolü ve sayaç artırımını atomik yapar — eşzamanlı iki istek limitin
üzerine çıkamaz. Sayaç uygulama katmanında değil DB'de tutulur, çünkü istemciye
güvenilmez.

## 3. Veri modeli

| Tablo | Amaç | Erişim özeti |
|---|---|---|
| `profiles` | Kimlik, rol, dil | Sahibi okur/yazar (rol hariç); atanmış diyetisyen okur |
| `health_profiles` | Sağlık verisi (KVKK hassas) | Sahibi tam; atanmış diyetisyen salt okur |
| `diet_plans` | AI/diyetisyen planları, `plan_json` | Sahibi tam; diyetisyen okur + yazar |
| `food_logs` / `water_logs` | Öğün ve su takibi | Sahibi tam; diyetisyen salt okur |
| `progress` | Kilo ve ölçüm geçmişi | Sahibi tam; diyetisyen salt okur |
| `dietitians` | Diyetisyen vitrini (bio, uzmanlık) | Giriş yapan herkes okur — kasıtlı |
| `assignments` | Kullanıcı–diyetisyen eşleşmesi | Taraflar okur; oluşturma sunucu tarafında |
| `messages` | Realtime mesajlaşma | Yalnızca eşleşmiş çiftler |
| `ai_chats` | AI sohbet geçmişi | Yalnızca sahibi |
| `ai_usage` | Günlük AI kotası | Sahibi okur; yazma yalnızca RPC ile |
| `emergency_logs` | Acil buton kullanım kaydı | Yalnızca sahibi (silme dahil) |

`auth.users`'a yeni kayıt düştüğünde `handle_new_user()` trigger'ı ilgili
`profiles` satırını açar; istemcinin profil oluşturma sorumluluğu yoktur.

SQL dosyaları çalıştırma sırasına göre: `schema.sql` → `policies.sql` →
`ai_usage.sql` → `plan_json.sql` → `emergency_logs.sql` → `policies_hardening.sql`.

## 4. AI katmanı

Tek bir Edge Function (`supabase/functions/ai/index.ts`) üç modu karşılar:

- `diet_plan` — 7 günlük plan üretir. Önce aktif plan önbellekten döner;
  yalnızca `forceRegenerate` ile yeniden üretilir. Plan üretimi pahalıdır,
  varsayılan davranış üretmemektir.
- `revise` — mevcut planı kullanıcı geri bildirimine göre revize eder,
  şikâyet edilmeyen kısımları korur.
- `chat` — beslenme danışmanı sohbeti.

**Yapılandırılmış çıktı.** Plan serbest metin değil, Gemini'nin `responseSchema`
özelliğiyle şemaya bağlanmış JSON'dur ve `diet_plans.plan_json` kolonunda
saklanır. Serbest metin plan denendi ve bırakıldı: kesilme riski vardı, arayüzde
öğün bazlı gösterim yapılamıyordu ve markdown ayrıştırması kırılgandı.

**Profil sunucuda okunur.** İstemci AI'ya kullanıcı profili göndermez; Edge
Function `health_profiles`'ı kullanıcının kendi JWT'siyle (yani RLS altında)
okur. Böylece istemci profil verisini manipüle ederek başkasının bağlamıyla
plan üretemez.

**Edge Function service_role kullanmaz.** Kullanıcının JWT'siyle çalışır, yani
RLS'in altındadır. Bir hata durumunda etki alanı o kullanıcının kendi verisiyle
sınırlı kalır.

## 5. İstemci yapısı

```
lib/
├── main.dart                 # AuthGate, 5 sekmeli kabuk, yönlendirme
├── config/
│   ├── app_theme.dart        # tek kaynak tema ("Derin Teal")
│   ├── locale_controller.dart# dil tercihi, ilk frame'den önce yüklenir
│   └── supabase_config.dart  # URL + anon key
├── l10n/                     # TR/EN, 343 anahtar, gen-l10n ile üretilir
├── pages/
│   ├── onboarding/           # çok adımlı profil toplama akışı
│   ├── diet_plan_page.dart   # plan görüntüleme + revizyon
│   ├── food_tracking_page.dart
│   ├── progress_page.dart    # fl_chart grafikleri
│   ├── ai_chat_page.dart
│   ├── dietitian_chat_page.dart  # Supabase Realtime
│   └── emergency_page.dart   # "acil buton" akışı
├── services/ai_service.dart  # Edge Function ile tek temas noktası
└── widgets/                  # mesh_blob, page_header
```

**Türkçe/İngilizce baştan içeride.** Metinler i18n'e alınmış durumda (`app_tr.arb`
şablon, `app_en.arb` simetrik). Bunun sonradan eklenmesi tüm sayfalara dokunmayı
gerektirirdi.

**Tasarım dili.** Klasik `AppBar` yerine `PageHeader` bileşeni; kenarlıksız
kartlar, geniş köşe yarıçapı, başlıklarda serif (Fraunces) — gövde fontlarına
dokunulmadan. Amaç varsayılan Material görünümünden uzaklaşmak.

**Animasyon performans ilkesi.** `MeshBlob` (shader tabanlı) yalnızca geçici,
odaktaki anlarda kullanılır — örneğin AI yanıt beklenirken. Sürekli ekranda
duran blob'lar (navigasyon sekmesi, sohbet avatarları) shader kullanmayan
`FlatBlob` ile çizilir: statik degrade dolgu + her karede yalnızca kırpma
yolunun değiştiği bir clipper, `RepaintBoundary` ile sarılı.

## 6. Bilinen sınırlar

- Diyetisyen kaydı ve kullanıcıya atanması henüz uygulama içinden yapılmıyor;
  `assignments` satırı sunucu tarafında oluşturuluyor (bkz. SETUP.md).
- Besin veritabanı yok; öğün kalorileri kullanıcı girişiyle geliyor.
- Ödeme/abonelik katmanı yok.
- Testler yalnızca manuel; otomatik test kapsamı yok.
