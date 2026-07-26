-- Diyet Uygulaması — Yapılandırılmış diyet planı (A2a)
-- Çalıştırma: schema.sql'den SONRA, SQL Editor'de manuel çalıştır.
-- Amaç: Diyet planını serbest metin yerine yapılandırılmış JSON olarak saklamak.
-- content kolonu geriye dönük uyumluluk için kalır; yeni satırlarda planın
-- title'ı yazılır (eski serbest metin plan davranışı kalkıyor).

alter table public.diet_plans add column if not exists plan_json jsonb;
