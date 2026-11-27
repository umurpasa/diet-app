// Hachibu — Hesap silme Edge Function'ı
//
// Çağıran kullanıcının hesabını ve TÜM verisini kalıcı olarak siler.
// Neden Edge Function? Auth kullanıcısını silmek service_role yetkisi ister;
// o anahtar istemciye ASLA gitmez. Burada sunucu ortamından okunur.
//
// Silinen veri: auth.users satırı silinince public.profiles (on delete cascade)
// ve profiles'a bağlı tüm tablolar (health_profiles, diet_plans, food_logs,
// water_logs, progress, ai_chats, ai_usage, emergency_logs, messages,
// assignments, dietitians) cascade ile silinir.
//
// Güvenlik:
// - Kimlik yalnızca Authorization başlığındaki JWT'den alınır; gövdeden
//   kullanıcı id'si KABUL EDİLMEZ (başkasının hesabını silmek mümkün değil).
// - Yanlışlıkla çağrıya karşı gövdede {"confirm": "DELETE"} zorunlu.
// - Deploy'da JWT doğrulaması açık kalır (varsayılan; --no-verify-jwt KULLANMA).
//
// İstek:  POST  { "confirm": "DELETE" }   (supabase.functions.invoke ile)
// Yanıt:  200 { "deleted": true }  |  4xx/5xx { "error": "..." }

import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const url = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !anonKey || !serviceKey) {
    console.error("delete-account: missing env");
    return json({ error: "Server misconfigured" }, 500);
  }

  // 1) Onay alanı
  let body: { confirm?: unknown } = {};
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }
  if (body.confirm !== "DELETE") {
    return json({ error: "Confirmation missing" }, 400);
  }

  // 2) Çağıranı JWT'sinden doğrula
  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader.startsWith("Bearer ")) return json({ error: "Unauthorized" }, 401);

  const userClient = createClient(url, anonKey, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false },
  });
  const { data: userData, error: userErr } = await userClient.auth.getUser();
  if (userErr || !userData?.user) return json({ error: "Unauthorized" }, 401);
  const userId = userData.user.id;

  // 3) service_role ile sil (cascade tüm verileri götürür)
  const admin = createClient(url, serviceKey, { auth: { persistSession: false } });
  const { error: delErr } = await admin.auth.admin.deleteUser(userId);
  if (delErr) {
    console.error("delete-account: deleteUser failed", delErr.message);
    return json({ error: "Delete failed" }, 500);
  }

  // Kişisel veri loglanmaz; yalnızca olay.
  console.log("delete-account: account deleted");
  return json({ deleted: true });
});
