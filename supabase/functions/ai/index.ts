// Supabase Edge Function: "ai"
// AI diyet planı üretimi/revizyonu + AI sohbet danışmanı. Gemini çağrısı
// SUNUCUDA yapılır; API anahtarı istemciye ASLA gitmez (GEMINI_API_KEY secret).
//
// İstek gövdesi (JSON):
//   { "mode": "diet_plan", "forceRegenerate": false }          -> plan döndür/üret
//   { "mode": "revise", "reasons": ["..."], "note": "..." }    -> aktif planı revize et
//   { "mode": "chat", "message": "..." }                       -> sohbet yanıtı
//
// Yanıt:
//   diet_plan / revise: { "plan": { ... }, "cached": true|false }
//   chat:               { "content": "...", "cached": false }
//   Hata: { "error": "..." }  (uygun HTTP status ile; limit için 429)
//
// Kimlik: İstemci supabase.functions.invoke ile çağırınca kullanıcı JWT'si
// Authorization başlığında otomatik gelir. Bu JWT ile oluşturulan Supabase
// istemcisi RLS kapsamında çalışır → kullanıcı yalnızca kendi verisine erişir.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// --- Ayarlanabilir sabitler (secret olarak override edilebilir) ---
const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY") ?? "";
const GEMINI_MODEL = Deno.env.get("GEMINI_MODEL") ?? "gemini-3.5-flash";
const DAILY_LIMIT = parseInt(Deno.env.get("AI_DAILY_LIMIT") ?? "20", 10);

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

const SYSTEM_PERSONA =
  "Sen deneyimli bir beslenme ve diyet uzmanısın. Sağlıklı beslenme, kilo " +
  "yönetimi ve sürdürülebilir alışkanlıklar konusunda profesyonel, güvenli " +
  "ve kişiye özel tavsiyeler verirsin. Tıbbi teşhis koymazsın; gerektiğinde " +
  "kullanıcıyı bir hekime/diyetisyene yönlendirirsin. Türkçe yanıt ver.";

// Yapılandırılmış plan modları için ortak kurallar (selamlama/giriş yok, salt JSON).
const PLAN_RULES =
  "Yanıtın YALNIZCA verilen şemaya uygun JSON diyet planı olsun; selamlama, " +
  "giriş veya kapanış cümlesi ekleme. Tüm metin alanları Türkçe olsun. " +
  "health_note alanına kullanıcının sağlık geçmişi ve alerjilerine dair " +
  "uyarıları yaz. days dizisi 7 gün içersin (day: 1-7); her gün 3 ana öğün " +
  "ve 2 ara öğün olsun, saatler 'HH:MM' biçiminde verilsin. " +
  "Sigara/alkol/uyku gibi yaşam tarzı bilgilerini planı ve önerileri " +
  "kişiselleştirmek için kullan; kullanıcıya bu alışkanlıkları hakkında " +
  "istenmedikçe öğüt verme. Kullanıcının zayıf anları (ör. gece atıştırması, " +
  "tatlı krizi) varsa planı buna göre kur — ör. gece atıştırması olana akşam " +
  "için bilinçli, sağlıklı bir ara öğün koy. Sevmediği yiyecekleri MÜMKÜNSE " +
  "plana koyma; alerjilerin aksine bu kesin yasak değil, tercihtir. Beslenme " +
  "tarzı vejetaryen/vegan ise plan buna KESİNLİKLE uysun (vegan plana " +
  "hayvansal ürün koyma).";

// Sohbet moduna özgü kurallar (SYSTEM_PERSONA'dan bilinçli ayrı tutulur).
const CHAT_RULES =
  "Sigara/alkol/uyku gibi yaşam tarzı bilgilerini önerilerini " +
  "kişiselleştirmek için kullan; kullanıcıya bu alışkanlıkları hakkında " +
  "istenmedikçe öğüt verme.";

const PLAN_SYSTEM = `${SYSTEM_PERSONA}\n\n${PLAN_RULES}`;

const REVISE_SYSTEM =
  `${SYSTEM_PERSONA}\n\nDiyetisyen olarak mevcut planı kullanıcının geri ` +
  "bildirimine göre REVİZE et; şikayet edilmeyen kısımları olabildiğince " +
  `aynen koru.\n\n${PLAN_RULES}`;

// Gemini structured output şeması (responseSchema formatı).
const PLAN_SCHEMA = {
  type: "OBJECT",
  required: ["title", "daily_kcal", "macros", "health_note", "days"],
  properties: {
    title: { type: "STRING" },
    daily_kcal: { type: "INTEGER" },
    macros: {
      type: "OBJECT",
      required: ["carb_g", "protein_g", "fat_g"],
      properties: {
        carb_g: { type: "INTEGER" },
        protein_g: { type: "INTEGER" },
        fat_g: { type: "INTEGER" },
      },
    },
    health_note: { type: "STRING" },
    days: {
      type: "ARRAY",
      items: {
        type: "OBJECT",
        required: ["day", "meals"],
        properties: {
          day: { type: "INTEGER" },
          meals: {
            type: "ARRAY",
            items: {
              type: "OBJECT",
              required: ["type", "time", "name", "kcal"],
              properties: {
                type: {
                  type: "STRING",
                  enum: ["breakfast", "lunch", "dinner", "snack"],
                },
                time: { type: "STRING" },
                name: { type: "STRING" },
                kcal: { type: "INTEGER" },
              },
            },
          },
        },
      },
    },
  },
};

// --- preferences jsonb → okunur Türkçe bağlam ---
// Anahtar/değer sözlüğü lib/pages/onboarding/onboarding_data.dart ile birebir
// aynı (İngilizce snake_case). conditions*/allergies*/medications buraya
// bilinçli olarak alınmaz: text kolon özetlerinde (health_history, allergies)
// zaten var. onboarding_completed/onboarding_step akış bilgisidir, bağlama girmez.

const PREF_LABEL_TR: Record<string, string> = {
  sex: "Cinsiyet",
  activity_level: "Aktivite düzeyi",
  water_glasses: "Su tüketimi",
  sleep_hours: "Uyku",
  smoking: "Sigara",
  alcohol: "Alkol",
  meals_per_day: "Ana öğün sayısı",
  skips_breakfast: "Kahvaltı",
  eating_out: "Dışarıda yeme",
  diet_style: "Beslenme tarzı",
};

const PREF_VALUE_TR: Record<string, Record<string, string>> = {
  sex: { female: "kadın", male: "erkek" },
  activity_level: {
    sedentary: "hareketsiz (masa başı)",
    light: "hafif aktif",
    moderate: "orta düzeyde aktif",
    active: "aktif",
    very_active: "çok aktif",
  },
  water_glasses: {
    "0-2": "günde 0-2 bardak",
    "3-5": "günde 3-5 bardak",
    "6-8": "günde 6-8 bardak",
    "8+": "günde 8 bardaktan fazla",
  },
  sleep_hours: {
    "<5": "günde 5 saatten az",
    "5-6": "günde 5-6 saat",
    "7-8": "günde 7-8 saat",
    "8+": "günde 8 saatten fazla",
  },
  smoking: { none: "kullanmıyor", occasional: "ara sıra", regular: "düzenli" },
  alcohol: { none: "kullanmıyor", occasional: "ara sıra", regular: "düzenli" },
  meals_per_day: {
    "2": "günde 2",
    "3": "günde 3",
    "4+": "günde 4 veya daha fazla",
  },
  skips_breakfast: {
    never: "hiç atlamaz",
    sometimes: "bazen atlar",
    often: "sık sık atlar",
  },
  eating_out: {
    rarely: "nadiren",
    "1-2_per_week": "haftada 1-2 kez",
    "3+_per_week": "haftada 3 veya daha fazla",
    daily: "her gün",
  },
  diet_style: {
    omnivore: "omnivor (her şeyi yer)",
    vegetarian: "vejetaryen",
    vegan: "vegan",
  },
};

const GOAL_TYPE_TR: Record<string, string> = {
  lose: "kilo vermek",
  gain: "kilo almak",
  maintain: "kilosunu korumak",
  healthy: "sağlıklı beslenmek",
};

const PACE_TR: Record<string, string> = {
  slow: "yavaş ve sürdürülebilir",
  balanced: "dengeli",
  fast: "hızlı",
};

const WEAK_MOMENT_TR: Record<string, string> = {
  night_snacking: "gece atıştırması",
  sweet_craving: "tatlı krizi",
  hunger_between_meals: "öğün aralarında acıkma",
  stress_eating: "stres/duygusal yeme",
};

// Bilinmeyen anahtar/değerler sessizce atlanır; boş/eksik jsonb'de "" döner.
function preferencesToText(prefs: unknown): string {
  if (!prefs || typeof prefs !== "object" || Array.isArray(prefs)) return "";
  const p = prefs as Record<string, unknown>;
  const lines: string[] = [];

  // Hedef nesnesi: tip + hedef kilo + tempo.
  const goal = p.goal;
  if (goal && typeof goal === "object" && !Array.isArray(goal)) {
    const g = goal as Record<string, unknown>;
    const type = typeof g.type === "string" ? GOAL_TYPE_TR[g.type] : undefined;
    if (type) {
      const extras: string[] = [];
      if (typeof g.target_weight_kg === "number") {
        extras.push(`hedef ${g.target_weight_kg} kg`);
      }
      const pace = typeof g.pace === "string" ? PACE_TR[g.pace] : undefined;
      if (pace) extras.push(`${pace} tempo`);
      lines.push(
        `Hedef: ${type}${extras.length ? ` (${extras.join(", ")})` : ""}`,
      );
    }
  }

  // Tek değerli anahtarlar.
  for (const [key, label] of Object.entries(PREF_LABEL_TR)) {
    const value = p[key];
    const tr = typeof value === "string"
      ? PREF_VALUE_TR[key]?.[value]
      : undefined;
    if (tr) lines.push(`${label}: ${tr}`);
  }

  // Zayıf anlar (liste; "none" sözlükte olmadığından kendiliğinden atlanır).
  if (Array.isArray(p.weak_moments)) {
    const moments = p.weak_moments
      .filter((m): m is string => typeof m === "string")
      .map((m) => WEAK_MOMENT_TR[m])
      .filter(Boolean);
    if (moments.length) lines.push(`Zayıf anları: ${moments.join(", ")}`);
  }

  // Sevmediği yiyecekler (serbest metin).
  if (typeof p.disliked_foods === "string" && p.disliked_foods.trim()) {
    lines.push(`Sevmediği yiyecekler: ${p.disliked_foods.trim()}`);
  }

  return lines.join("; ");
}

// Kullanıcının sağlık profilini okunabilir bir metne çevirir.
function profileToText(p: Record<string, unknown> | null): string {
  if (!p) {
    return "(Kullanıcı henüz profil bilgisi girmemiş. Genel, güvenli ve " +
      "profil doldurmayı teşvik eden bir yanıt ver.)";
  }
  const parts = [
    p.age != null ? `Yaş: ${p.age}` : null,
    p.height_cm != null ? `Boy: ${p.height_cm} cm` : null,
    p.weight_kg != null ? `Kilo: ${p.weight_kg} kg` : null,
    p.goal ? `Hedef: ${p.goal}` : null,
    p.health_history ? `Sağlık geçmişi: ${p.health_history}` : null,
    p.allergies ? `Alerjiler: ${p.allergies}` : null,
  ].filter(Boolean);
  const base = parts.length ? parts.join(", ") : "(Profil boş.)";
  // preferences boşsa çıktı eskisiyle birebir aynı kalır (geriye uyumluluk).
  const prefText = preferencesToText(p.preferences);
  return prefText ? `${base}\nYaşam tarzı ve tercihler: ${prefText}` : base;
}

// Gemini generateContent çağrısı. systemInstruction + tek user turn (+ opsiyonel geçmiş).
// responseSchema verilirse structured output (application/json) istenir.
async function callGemini(
  systemInstruction: string,
  userText: string,
  history: { role: string; content: string }[] = [],
  responseSchema?: Record<string, unknown>,
): Promise<string> {
  const url =
    `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`;

  const contents = [
    ...history.map((h) => ({
      role: h.role === "assistant" ? "model" : "user",
      parts: [{ text: h.content }],
    })),
    { role: "user", parts: [{ text: userText }] },
  ];

  const generationConfig: Record<string, unknown> = {
    temperature: 0.7,
    maxOutputTokens: 8192,
    // Düşünme tokenları maxOutputTokens'tan düşüyor; bütçeyi sınırlamazsak
    // uzun planlarda asıl yanıt kesiliyordu.
    thinkingConfig: { thinkingBudget: 512 },
  };
  if (responseSchema) {
    generationConfig.responseMimeType = "application/json";
    generationConfig.responseSchema = responseSchema;
  }

  const res = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      systemInstruction: { parts: [{ text: systemInstruction }] },
      contents,
      generationConfig,
    }),
  });

  if (!res.ok) {
    const errText = await res.text();
    console.error("Gemini error", res.status, errText);
    throw new Error(`Gemini API hatası (${res.status})`);
  }

  const data = await res.json();
  if (data?.candidates?.[0]?.finishReason === "MAX_TOKENS") {
    console.error("Gemini yanıtı token limitinde kesildi (finishReason=MAX_TOKENS)");
  }
  const text = data?.candidates?.[0]?.content?.parts
    ?.map((x: { text?: string }) => x.text ?? "")
    .join("") ?? "";
  if (!text.trim()) throw new Error("Gemini boş yanıt döndürdü");
  return text.trim();
}

// Gemini'nin JSON yanıtını parse eder; bozuksa null döner (çağıran 502 verir).
function parsePlan(raw: string): Record<string, unknown> | null {
  try {
    const plan = JSON.parse(raw);
    if (
      plan && typeof plan === "object" && !Array.isArray(plan) &&
      typeof plan.title === "string" && Array.isArray(plan.days)
    ) {
      return plan as Record<string, unknown>;
    }
  } catch {
    // parse hatası aşağıda null olarak raporlanır
  }
  console.error("Gemini plan yanıtı parse edilemedi:", raw.slice(0, 500));
  return null;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "Yalnızca POST" }, 405);
  }
  if (!GEMINI_API_KEY) {
    return json({ error: "Sunucu yapılandırması eksik (GEMINI_API_KEY)." }, 500);
  }

  // Kullanıcı JWT'siyle RLS-kapsamlı istemci.
  const authHeader = req.headers.get("Authorization") ?? "";
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const { data: userData, error: userErr } = await supabase.auth.getUser();
  const user = userData?.user;
  if (userErr || !user) {
    return json({ error: "Oturum doğrulanamadı." }, 401);
  }

  let body: {
    mode?: string;
    message?: string;
    forceRegenerate?: boolean;
    reasons?: string[];
    note?: string;
  };
  try {
    body = await req.json();
  } catch {
    return json({ error: "Geçersiz JSON gövdesi." }, 400);
  }
  const mode = body.mode;

  // Günlük AI kullanım limiti (üretim maliyeti oluşan her yol bunu çağırır).
  async function checkLimit(): Promise<Response | null> {
    const { data: allowed, error: rpcErr } = await supabase.rpc(
      "check_and_increment_ai_usage",
      { p_limit: DAILY_LIMIT },
    );
    if (rpcErr) throw rpcErr;
    if (!allowed) {
      return json(
        { error: `Günlük AI limitine ulaştın (${DAILY_LIMIT}). Yarın tekrar dene.` },
        429,
      );
    }
    return null;
  }

  async function getProfile() {
    const { data: profile } = await supabase
      .from("health_profiles")
      .select(
        "age, height_cm, weight_kg, goal, health_history, allergies, preferences",
      )
      .eq("user_id", user!.id)
      .maybeSingle();
    return profile;
  }

  // Eski planları pasifleştirip yeni aktif planı kaydeder.
  // content'e geriye dönük uyumluluk için planın title'ı yazılır.
  async function savePlan(plan: Record<string, unknown>) {
    await supabase
      .from("diet_plans")
      .update({ is_active: false })
      .eq("user_id", user!.id)
      .eq("is_active", true);
    await supabase.from("diet_plans").insert({
      user_id: user!.id,
      plan_json: plan,
      content: typeof plan.title === "string" ? plan.title : "Diyet planı",
      generated_by: "ai",
      is_active: true,
    });
  }

  try {
    // ---------------- DIYET PLANI ----------------
    if (mode === "diet_plan") {
      // 1) forceRegenerate değilse önbellekteki aktif planı döndür.
      //    (plan_json'ı olmayan eski metin planlar önbellek sayılmaz.)
      if (!body.forceRegenerate) {
        const { data: existing } = await supabase
          .from("diet_plans")
          .select("plan_json")
          .eq("user_id", user.id)
          .eq("is_active", true)
          .order("created_at", { ascending: false })
          .limit(1)
          .maybeSingle();
        if (existing?.plan_json) {
          return json({ plan: existing.plan_json, cached: true });
        }
      }

      // 2) Kullanım limiti.
      const limited = await checkLimit();
      if (limited) return limited;

      // 3) Profili oku ve Gemini ile yapılandırılmış plan üret.
      const profile = await getProfile();
      const prompt =
        "Aşağıdaki kullanıcı bilgilerine göre 7 günlük, dengeli ve " +
        "uygulanabilir bir diyet planı oluştur. Alerjileri ve sağlık " +
        "geçmişini kesinlikle dikkate al.\n\n" +
        `Kullanıcı bilgileri: ${profileToText(profile)}`;
      const raw = await callGemini(PLAN_SYSTEM, prompt, [], PLAN_SCHEMA);

      const plan = parsePlan(raw);
      if (!plan) {
        return json(
          { error: "AI geçerli bir plan üretemedi. Lütfen tekrar dene." },
          502,
        );
      }

      // 4) Önbelleğe yaz ve döndür.
      await savePlan(plan);
      return json({ plan, cached: false });
    }

    // ---------------- PLAN REVİZYONU ----------------
    if (mode === "revise") {
      const reasons = (body.reasons ?? []).filter((r) =>
        typeof r === "string" && r.trim()
      );
      const note = (body.note ?? "").trim();
      if (!reasons.length && !note) {
        return json({ error: "Revizyon için en az bir neden belirtmelisin." }, 400);
      }

      // 1) Aktif planın JSON'ı olmadan revizyon yapılamaz.
      const { data: existing } = await supabase
        .from("diet_plans")
        .select("plan_json")
        .eq("user_id", user.id)
        .eq("is_active", true)
        .order("created_at", { ascending: false })
        .limit(1)
        .maybeSingle();
      if (!existing?.plan_json) {
        return json({ error: "Önce bir plan oluşturmalısın." }, 400);
      }

      // 2) Kullanım limiti.
      const limited = await checkLimit();
      if (limited) return limited;

      // 3) Mevcut plan + geri bildirimle revize plan üret.
      const profile = await getProfile();
      const prompt =
        `Mevcut plan (JSON): ${JSON.stringify(existing.plan_json)}\n\n` +
        `Kullanıcının şikayetleri: ${reasons.join("; ") || "(belirtilmedi)"}\n` +
        (note ? `Kullanıcının notu: ${note}\n` : "") +
        `\nKullanıcı bilgileri: ${profileToText(profile)}`;
      const raw = await callGemini(REVISE_SYSTEM, prompt, [], PLAN_SCHEMA);

      const plan = parsePlan(raw);
      if (!plan) {
        return json(
          { error: "AI geçerli bir plan üretemedi. Lütfen tekrar dene." },
          502,
        );
      }

      // 4) Revize plan yeni aktif plan olur.
      await savePlan(plan);
      return json({ plan, cached: false });
    }

    // ---------------- SOHBET ----------------
    if (mode === "chat") {
      const message = (body.message ?? "").trim();
      if (!message) return json({ error: "Boş mesaj." }, 400);

      // 1) Limit.
      const limited = await checkLimit();
      if (limited) return limited;

      // 2) Profil + son sohbet geçmişi (bağlam için).
      const profile = await getProfile();

      const { data: recent } = await supabase
        .from("ai_chats")
        .select("role, content")
        .eq("user_id", user.id)
        .order("created_at", { ascending: false })
        .limit(10);
      const history = (recent ?? []).reverse(); // eskiden yeniye

      const system =
        `${SYSTEM_PERSONA}\n\n${CHAT_RULES}\n\nKullanıcı profili: ${profileToText(profile)}`;
      const content = await callGemini(system, message, history);

      // 3) Sohbeti kaydet (kullanıcı + asistan).
      await supabase.from("ai_chats").insert([
        { user_id: user.id, role: "user", content: message },
        { user_id: user.id, role: "assistant", content },
      ]);

      return json({ content, cached: false });
    }

    return json({ error: `Bilinmeyen mode: ${mode}` }, 400);
  } catch (e) {
    console.error("ai function error", e);
    return json({ error: "AI isteği işlenemedi. Lütfen tekrar dene." }, 500);
  }
});
