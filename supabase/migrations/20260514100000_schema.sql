create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id           uuid primary key references auth.users (id) on delete cascade,
  user_name    text,
  bio          text,
  avatar_url   text,
  home_address text,
  home_lat     double precision,
  home_lng     double precision,
  created_at   timestamptz not null default now()
);

create table if not exists public.categories (
  id         uuid primary key default gen_random_uuid(),
  name       text not null unique,
  icon       text,
  created_at timestamptz not null default now()
);

create table if not exists public.skills (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  user_name   text,
  skill_title text not null,
  description text not null,
  skill_type  text not null default 'offering',
  category_id uuid references public.categories (id) on delete set null,
  tags        text[] not null default '{}',
  lat         double precision not null,
  lng         double precision not null,
  status      text not null default 'active',
  created_at  timestamptz not null default now()
);

alter table public.skills add column if not exists skill_type text not null default 'offering';
alter table public.skills add column if not exists category_id uuid references public.categories (id) on delete set null;
alter table public.skills add column if not exists user_name text;
alter table public.skills add column if not exists tags text[] not null default '{}';
alter table public.skills add column if not exists status text not null default 'active';
alter table public.skills add column if not exists created_at timestamptz not null default now();
alter table public.skills drop column if exists points_per_hour;

alter table public.profiles add column if not exists user_name text;
alter table public.profiles add column if not exists bio text;
alter table public.profiles add column if not exists avatar_url text;
alter table public.profiles add column if not exists home_address text;
alter table public.profiles add column if not exists home_lat double precision;
alter table public.profiles add column if not exists home_lng double precision;
alter table public.profiles add column if not exists created_at timestamptz not null default now();

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'skills_skill_type_check') then
    alter table public.skills
      add constraint skills_skill_type_check check (skill_type in ('offering', 'searching'));
  end if;
end $$;

create table if not exists public.ratings (
  id            uuid primary key default gen_random_uuid(),
  rater_id      uuid not null references auth.users (id) on delete cascade,
  rater_name    text,
  rated_user_id uuid not null references auth.users (id) on delete cascade,
  skill_id      uuid references public.skills (id) on delete set null,
  rating        smallint not null check (rating between 1 and 5),
  comment       text,
  created_at    timestamptz not null default now(),
  unique (rater_id, rated_user_id)
);

alter table public.ratings add column if not exists rater_name text;
alter table public.ratings add column if not exists skill_id uuid references public.skills (id) on delete set null;
alter table public.ratings add column if not exists comment text;
alter table public.ratings add column if not exists created_at timestamptz not null default now();

create table if not exists public.conversations (
  id              uuid primary key default gen_random_uuid(),
  name            text,
  type            text not null default 'direct' check (type in ('direct', 'group')),
  skill_id        uuid references public.skills (id) on delete set null,
  created_by      uuid not null references auth.users (id) on delete cascade,
  last_message    text,
  last_message_at timestamptz,
  created_at      timestamptz not null default now()
);

create table if not exists public.conversation_members (
  id              uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  user_id         uuid not null references auth.users (id) on delete cascade,
  user_name       text,
  avatar_url      text,
  joined_at       timestamptz not null default now(),
  unique (conversation_id, user_id)
);

create table if not exists public.messages (
  id              uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  sender_id       uuid not null references auth.users (id) on delete cascade,
  sender_name     text not null default '',
  content         text not null,
  created_at      timestamptz not null default now()
);

create table if not exists public.skill_requests (
  id               uuid primary key default gen_random_uuid(),
  skill_id         uuid not null references public.skills (id) on delete cascade,
  skill_title      text,
  requester_id     uuid not null references auth.users (id) on delete cascade,
  requester_name   text,
  requester_avatar text,
  skill_owner_id   uuid not null references auth.users (id) on delete cascade,
  status           text not null default 'pending'
                   check (status in ('pending', 'accepted', 'rejected')),
  message          text,
  created_at       timestamptz not null default now()
);

create table if not exists public.skill_reports (
  id          uuid primary key default gen_random_uuid(),
  skill_id    uuid not null references public.skills (id) on delete cascade,
  reporter_id uuid not null references auth.users (id) on delete cascade,
  reason      text not null,
  reviewed    boolean not null default false,
  created_at  timestamptz not null default now(),
  unique (skill_id, reporter_id)
);

create table if not exists public.device_tokens (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users (id) on delete cascade,
  fcm_token  text not null unique,
  platform   text not null default 'android',
  updated_at timestamptz not null default now()
);

with ranked as (
  select id, first_value(id) over (partition by name order by ctid) as keep_id
  from public.categories
)
update public.skills s
set category_id = r.keep_id
from ranked r
where s.category_id = r.id and r.id <> r.keep_id;

delete from public.categories a
using public.categories b
where a.name = b.name and a.ctid > b.ctid;

delete from public.ratings a
using public.ratings b
where a.rater_id = b.rater_id and a.rated_user_id = b.rated_user_id and a.ctid < b.ctid;

delete from public.conversation_members a
using public.conversation_members b
where a.conversation_id = b.conversation_id and a.user_id = b.user_id and a.ctid > b.ctid;

delete from public.skill_reports a
using public.skill_reports b
where a.skill_id = b.skill_id and a.reporter_id = b.reporter_id and a.ctid > b.ctid;

delete from public.device_tokens a
using public.device_tokens b
where a.fcm_token = b.fcm_token and a.ctid < b.ctid;

create unique index if not exists categories_name_key on public.categories (name);
create unique index if not exists ratings_rater_id_rated_user_id_key on public.ratings (rater_id, rated_user_id);
create unique index if not exists conversation_members_conversation_id_user_id_key on public.conversation_members (conversation_id, user_id);
create unique index if not exists skill_reports_skill_id_reporter_id_key on public.skill_reports (skill_id, reporter_id);
create unique index if not exists device_tokens_fcm_token_key on public.device_tokens (fcm_token);

insert into public.categories (name, icon) values
  ('Garten',                '🌿'),
  ('IT & Technologie',      '💻'),
  ('Haushalt',              '🏠'),
  ('Handwerk',              '🔨'),
  ('Kochen & Backen',       '🍳'),
  ('Nachhilfe & Bildung',   '📚'),
  ('Fahrzeuge & Transport', '🚗'),
  ('Fitness & Gesundheit',  '💪'),
  ('Musik & Kunst',         '🎸'),
  ('Sprachen',              '🗣️')
on conflict (name) do nothing;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', true, 2097152, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

do $$
declare
  t text;
begin
  foreach t in array array['skills', 'messages', 'conversations', 'skill_requests'] loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;
