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
alter table public.skills drop column if exists points_per_hour;

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
