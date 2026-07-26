-- Diyet Uygulaması — Supabase şeması (MVP)
-- Çalıştırma: Supabase paneli > SQL Editor > New query > yapıştır > Run
-- Not: Tüm tablolarda RLS baştan AÇIK ve politikasız = erişim kapalı (güvenli varsayılan).
--      Erişim politikaları ayrı adımda (policies.sql) eklenir.

-- 1) Kimlik + rol (auth.users'a bağlı)
create table public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  role        text not null default 'user' check (role in ('user','dietitian')),
  locale      text not null default 'tr',
  full_name   text,
  created_at  timestamptz not null default now()
);

-- 2) Hassas sağlık profili (KVKK — ayrı tablo, sıkı RLS)
create table public.health_profiles (
  user_id         uuid primary key references public.profiles(id) on delete cascade,
  age             int,
  height_cm       numeric,
  weight_kg       numeric,
  goal            text,
  health_history  text,
  allergies       text,
  preferences     jsonb default '{}'::jsonb,
  updated_at      timestamptz not null default now()
);

-- 3) Diyet planları (AI veya diyetisyen üretimi)
create table public.diet_plans (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references public.profiles(id) on delete cascade,
  content       text not null,
  generated_by  text not null default 'ai' check (generated_by in ('ai','dietitian')),
  is_active     boolean not null default true,
  created_at    timestamptz not null default now()
);
create index diet_plans_user_idx on public.diet_plans(user_id, created_at desc);

-- 4) Öğün kaydı
create table public.food_logs (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles(id) on delete cascade,
  log_date    date not null default current_date,
  name        text not null,
  calories    int,
  meal_type   text,           -- kahvaltı/öğle/akşam/ara
  created_at  timestamptz not null default now()
);
create index food_logs_user_date_idx on public.food_logs(user_id, log_date);

-- 5) Su takibi (kullanıcı-gün başına tek satır)
create table public.water_logs (
  id        uuid primary key default gen_random_uuid(),
  user_id   uuid not null references public.profiles(id) on delete cascade,
  log_date  date not null default current_date,
  glasses   int not null default 0,
  unique (user_id, log_date)
);

-- 6) İlerleme (grafikler bu tablodan)
create table public.progress (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references public.profiles(id) on delete cascade,
  log_date      date not null default current_date,
  weight_kg     numeric,
  measurements  jsonb default '{}'::jsonb,
  created_at    timestamptz not null default now()
);
create index progress_user_date_idx on public.progress(user_id, log_date);

-- 7) Diyetisyen profili (profiles.role = 'dietitian')
create table public.dietitians (
  user_id      uuid primary key references public.profiles(id) on delete cascade,
  bio          text,
  specialties  text[] default '{}',
  capacity     int default 0,
  created_at   timestamptz not null default now()
);

-- 8) Kullanıcı-diyetisyen ataması
create table public.assignments (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references public.profiles(id) on delete cascade,
  dietitian_id  uuid not null references public.profiles(id) on delete cascade,
  package       text,
  active        boolean not null default true,
  started_at    timestamptz not null default now()
);
create index assignments_user_idx on public.assignments(user_id);
create index assignments_dietitian_idx on public.assignments(dietitian_id);

-- 9) Mesajlaşma (Supabase Realtime ile)
create table public.messages (
  id           uuid primary key default gen_random_uuid(),
  sender_id    uuid not null references public.profiles(id) on delete cascade,
  receiver_id  uuid not null references public.profiles(id) on delete cascade,
  body         text not null,
  created_at   timestamptz not null default now(),
  read_at      timestamptz
);
create index messages_pair_idx on public.messages(sender_id, receiver_id, created_at);

-- 10) AI sohbet geçmişi
create table public.ai_chats (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles(id) on delete cascade,
  role        text not null check (role in ('user','assistant')),
  content     text not null,
  created_at  timestamptz not null default now()
);
create index ai_chats_user_idx on public.ai_chats(user_id, created_at);

-- RLS'i tüm tablolarda aç (politikasız = kilitli, güvenli varsayılan)
alter table public.profiles        enable row level security;
alter table public.health_profiles enable row level security;
alter table public.diet_plans      enable row level security;
alter table public.food_logs       enable row level security;
alter table public.water_logs      enable row level security;
alter table public.progress        enable row level security;
alter table public.dietitians      enable row level security;
alter table public.assignments     enable row level security;
alter table public.messages        enable row level security;
alter table public.ai_chats        enable row level security;
