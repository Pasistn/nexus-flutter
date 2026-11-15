create or replace function public.is_conversation_member(p_conversation_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.conversation_members
    where conversation_id = p_conversation_id
      and user_id = auth.uid()
  );
$$;

revoke all on function public.is_conversation_member(uuid) from public, anon;
grant execute on function public.is_conversation_member(uuid) to authenticated;

create or replace function public.is_client_request()
returns boolean
language sql
stable
set search_path = ''
as $$
  select current_user in ('authenticated', 'anon');
$$;


do $$
declare
  r record;
begin
  for r in
    select policyname, tablename
    from pg_policies
    where schemaname = 'public'
      and tablename in (
        'profiles', 'skills', 'ratings', 'categories', 'conversations',
        'conversation_members', 'messages', 'skill_requests', 'skill_reports',
        'device_tokens'
      )
  loop
    execute format('drop policy %I on public.%I', r.policyname, r.tablename);
  end loop;
end $$;

alter table public.profiles             enable row level security;
alter table public.skills               enable row level security;
alter table public.ratings              enable row level security;
alter table public.categories           enable row level security;
alter table public.conversations        enable row level security;
alter table public.conversation_members enable row level security;
alter table public.messages             enable row level security;
alter table public.skill_requests       enable row level security;
alter table public.skill_reports        enable row level security;
alter table public.device_tokens        enable row level security;


create policy "profiles_select_own" on public.profiles
  for select to authenticated using (id = (select auth.uid()));
create policy "profiles_insert_own" on public.profiles
  for insert to authenticated with check (id = (select auth.uid()));
create policy "profiles_update_own" on public.profiles
  for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));
create policy "profiles_delete_own" on public.profiles
  for delete to authenticated using (id = (select auth.uid()));

create or replace view public.public_profiles
with (security_invoker = false) as
  select id, user_name, bio, avatar_url from public.profiles;

revoke all on public.public_profiles from public, anon, authenticated;
grant select on public.public_profiles to anon, authenticated;

create or replace function public.trg_profiles_validate()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if not public.is_client_request() then
    return new;
  end if;

  new.user_name    := nullif(btrim(new.user_name), '');
  new.bio          := nullif(btrim(new.bio), '');
  new.home_address := nullif(btrim(new.home_address), '');

  if char_length(new.user_name) > 50 then
    raise exception 'Der Name darf höchstens 50 Zeichen lang sein.';
  end if;
  if char_length(new.bio) > 500 then
    raise exception 'Die Bio darf höchstens 500 Zeichen lang sein.';
  end if;
  if char_length(new.home_address) > 300 then
    raise exception 'Die Adresse ist zu lang.';
  end if;
  if (new.home_lat is not null and new.home_lat not between -90 and 90)
     or (new.home_lng is not null and new.home_lng not between -180 and 180) then
    raise exception 'Ungültige Koordinaten.';
  end if;

  if new.avatar_url is not null
     and (tg_op = 'INSERT' or new.avatar_url is distinct from old.avatar_url)
     and new.avatar_url !~ ('^' || new.id::text || '/[A-Za-z0-9_-]{1,64}\.(jpg|jpeg|png|webp)$') then
    raise exception 'Ungültiges Profilbild.';
  end if;

  return new;
end;
$$;

drop trigger if exists profiles_validate on public.profiles;
create trigger profiles_validate
  before insert or update on public.profiles
  for each row execute function public.trg_profiles_validate();

create or replace function public.trg_profiles_sync()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.user_name is distinct from old.user_name
     or new.avatar_url is distinct from old.avatar_url then
    update public.skills
       set user_name = new.user_name
     where user_id = new.id;
    update public.conversation_members
       set user_name = new.user_name, avatar_url = new.avatar_url
     where user_id = new.id;
    update public.skill_requests
       set requester_name = new.user_name, requester_avatar = new.avatar_url
     where requester_id = new.id;
    update public.ratings
       set rater_name = new.user_name
     where rater_id = new.id;
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_sync on public.profiles;
create trigger profiles_sync
  after update on public.profiles
  for each row execute function public.trg_profiles_sync();


create policy "categories_select_all" on public.categories
  for select to anon, authenticated using (true);


create policy "skills_select_all" on public.skills
  for select to anon, authenticated using (true);
create policy "skills_insert_own" on public.skills
  for insert to authenticated with check (user_id = (select auth.uid()));
create policy "skills_update_own" on public.skills
  for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "skills_delete_own" on public.skills
  for delete to authenticated using (user_id = (select auth.uid()));

create or replace function public.trg_skills_validate()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if not public.is_client_request() then
    return new;
  end if;

  if tg_op = 'INSERT' then
    new.user_id    := auth.uid();
    new.created_at := now();

    if (select count(*) from public.skills
        where user_id = new.user_id
          and created_at > now() - interval '1 hour') >= 10 then
      raise exception 'Zu viele neue Einträge. Bitte versuche es später erneut.';
    end if;
  else
    new.user_id    := old.user_id;
    new.created_at := old.created_at;
  end if;

  new.user_name   := (select user_name from public.profiles where id = new.user_id);
  new.skill_title := btrim(new.skill_title);
  new.description := btrim(new.description);
  new.tags        := coalesce(new.tags, '{}');

  if char_length(coalesce(new.skill_title, '')) not between 1 and 100 then
    raise exception 'Der Titel muss zwischen 1 und 100 Zeichen lang sein.';
  end if;
  if char_length(coalesce(new.description, '')) not between 1 and 2000 then
    raise exception 'Die Beschreibung muss zwischen 1 und 2000 Zeichen lang sein.';
  end if;
  if cardinality(new.tags) > 10 then
    raise exception 'Maximal 10 Tags.';
  end if;
  if new.lat is null or new.lng is null
     or new.lat not between -90 and 90 or new.lng not between -180 and 180 then
    raise exception 'Ungültige Koordinaten.';
  end if;

  new.lat := round(new.lat::numeric, 3);
  new.lng := round(new.lng::numeric, 3);

  return new;
end;
$$;

drop trigger if exists skills_validate on public.skills;
create trigger skills_validate
  before insert or update on public.skills
  for each row execute function public.trg_skills_validate();


create policy "ratings_select_all" on public.ratings
  for select to anon, authenticated using (true);
create policy "ratings_insert_own" on public.ratings
  for insert to authenticated
  with check (rater_id = (select auth.uid()) and rated_user_id <> (select auth.uid()));
create policy "ratings_update_own" on public.ratings
  for update to authenticated
  using (rater_id = (select auth.uid()))
  with check (rater_id = (select auth.uid()) and rated_user_id <> (select auth.uid()));
create policy "ratings_delete_own" on public.ratings
  for delete to authenticated using (rater_id = (select auth.uid()));

create or replace function public.trg_ratings_validate()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if not public.is_client_request() then
    return new;
  end if;

  if tg_op = 'INSERT' then
    new.rater_id   := auth.uid();
    new.created_at := now();
  else
    new.rater_id      := old.rater_id;
    new.rated_user_id := old.rated_user_id;
  end if;

  if new.rated_user_id = new.rater_id then
    raise exception 'Du kannst dich nicht selbst bewerten.';
  end if;
  if new.rating is null or new.rating not between 1 and 5 then
    raise exception 'Die Bewertung muss zwischen 1 und 5 Sternen liegen.';
  end if;

  new.comment := nullif(btrim(new.comment), '');
  if char_length(new.comment) > 1000 then
    raise exception 'Der Kommentar darf höchstens 1000 Zeichen lang sein.';
  end if;

  if new.skill_id is not null and not exists (
    select 1 from public.skills
    where id = new.skill_id and user_id = new.rated_user_id
  ) then
    raise exception 'Der Skill gehört nicht zu dieser Person.';
  end if;

  new.rater_name := (select user_name from public.profiles where id = new.rater_id);
  return new;
end;
$$;

drop trigger if exists ratings_validate on public.ratings;
create trigger ratings_validate
  before insert or update on public.ratings
  for each row execute function public.trg_ratings_validate();


create policy "conversations_select_member" on public.conversations
  for select to authenticated
  using (public.is_conversation_member(id));

create policy "conversation_members_select_member" on public.conversation_members
  for select to authenticated
  using (public.is_conversation_member(conversation_id));

create or replace function public._get_or_create_direct_chat(
  p_user_a uuid,
  p_user_b uuid,
  p_skill_id uuid
) returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid;
begin
  perform pg_advisory_xact_lock(
    hashtextextended(least(p_user_a, p_user_b)::text || greatest(p_user_a, p_user_b)::text, 0)
  );

  select c.id into v_id
  from public.conversations c
  where c.type = 'direct'
    and exists (select 1 from public.conversation_members m
                where m.conversation_id = c.id and m.user_id = p_user_a)
    and exists (select 1 from public.conversation_members m
                where m.conversation_id = c.id and m.user_id = p_user_b)
  limit 1;

  if v_id is not null then
    return v_id;
  end if;

  insert into public.conversations (type, created_by, skill_id)
  values ('direct', p_user_a, p_skill_id)
  returning id into v_id;

  insert into public.conversation_members (conversation_id, user_id, user_name, avatar_url)
  select v_id, u.id, p.user_name, p.avatar_url
  from auth.users u
  left join public.profiles p on p.id = u.id
  where u.id in (p_user_a, p_user_b);

  return v_id;
end;
$$;

revoke all on function public._get_or_create_direct_chat(uuid, uuid, uuid)
  from public, anon, authenticated;

create or replace function public.create_direct_chat(
  p_other_user_id uuid,
  p_skill_id uuid default null
) returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'Nicht angemeldet.';
  end if;
  if p_other_user_id is null or p_other_user_id = v_uid then
    raise exception 'Ungültiger Chatpartner.';
  end if;
  if not exists (select 1 from auth.users where id = p_other_user_id) then
    raise exception 'Nutzer nicht gefunden.';
  end if;
  if p_skill_id is not null
     and not exists (select 1 from public.skills where id = p_skill_id) then
    p_skill_id := null;
  end if;
  if (select count(*) from public.conversations
      where created_by = v_uid and created_at > now() - interval '1 hour') >= 30 then
    raise exception 'Zu viele neue Chats. Bitte versuche es später erneut.';
  end if;

  return public._get_or_create_direct_chat(v_uid, p_other_user_id, p_skill_id);
end;
$$;

revoke all on function public.create_direct_chat(uuid, uuid) from public, anon;
grant execute on function public.create_direct_chat(uuid, uuid) to authenticated;

create or replace function public.create_group_chat(
  p_name text,
  p_member_ids uuid[]
) returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_name text := btrim(p_name);
  v_members uuid[];
  v_id uuid;
begin
  if v_uid is null then
    raise exception 'Nicht angemeldet.';
  end if;
  if char_length(coalesce(v_name, '')) not between 1 and 60 then
    raise exception 'Der Gruppenname muss zwischen 1 und 60 Zeichen lang sein.';
  end if;

  v_members := array(
    select distinct m from unnest(p_member_ids) m
    where m is not null and m <> v_uid
  );

  if cardinality(v_members) not between 1 and 50 then
    raise exception 'Eine Gruppe braucht 1 bis 50 weitere Mitglieder.';
  end if;
  if (select count(*) from auth.users where id = any(v_members)) <> cardinality(v_members) then
    raise exception 'Mindestens ein Mitglied wurde nicht gefunden.';
  end if;
  if (select count(*) from public.conversations
      where created_by = v_uid and created_at > now() - interval '1 hour') >= 30 then
    raise exception 'Zu viele neue Chats. Bitte versuche es später erneut.';
  end if;

  insert into public.conversations (name, type, created_by)
  values (v_name, 'group', v_uid)
  returning id into v_id;

  insert into public.conversation_members (conversation_id, user_id, user_name, avatar_url)
  select v_id, u.id, p.user_name, p.avatar_url
  from auth.users u
  left join public.profiles p on p.id = u.id
  where u.id = v_uid or u.id = any(v_members);

  return v_id;
end;
$$;

revoke all on function public.create_group_chat(text, uuid[]) from public, anon;
grant execute on function public.create_group_chat(text, uuid[]) to authenticated;


create policy "messages_select_member" on public.messages
  for select to authenticated
  using (public.is_conversation_member(conversation_id));
create policy "messages_insert_member" on public.messages
  for insert to authenticated
  with check (
    sender_id = (select auth.uid())
    and public.is_conversation_member(conversation_id)
  );

create or replace function public.trg_messages_validate()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if not public.is_client_request() then
    return new;
  end if;

  new.sender_id   := auth.uid();
  new.created_at  := now();
  new.sender_name := coalesce(
    (select user_name from public.profiles where id = new.sender_id),
    'Anonym'
  );

  if char_length(btrim(coalesce(new.content, ''))) = 0
     or char_length(new.content) > 4000 then
    raise exception 'Nachrichten müssen zwischen 1 und 4000 Zeichen lang sein.';
  end if;

  if (select count(*) from public.messages
      where sender_id = new.sender_id
        and created_at > now() - interval '1 minute') >= 30 then
    raise exception 'Du sendest zu schnell. Bitte warte einen Moment.';
  end if;

  return new;
end;
$$;

drop trigger if exists messages_validate on public.messages;
create trigger messages_validate
  before insert on public.messages
  for each row execute function public.trg_messages_validate();

create or replace function public.trg_messages_touch_conversation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.conversations
     set last_message = left(new.content, 200),
         last_message_at = new.created_at
   where id = new.conversation_id;
  return new;
end;
$$;

drop trigger if exists messages_touch_conversation on public.messages;
create trigger messages_touch_conversation
  after insert on public.messages
  for each row execute function public.trg_messages_touch_conversation();


create policy "skill_requests_select_party" on public.skill_requests
  for select to authenticated
  using (requester_id = (select auth.uid()) or skill_owner_id = (select auth.uid()));
create policy "skill_requests_insert_own" on public.skill_requests
  for insert to authenticated
  with check (requester_id = (select auth.uid()));
create policy "skill_requests_update_owner" on public.skill_requests
  for update to authenticated
  using (skill_owner_id = (select auth.uid()))
  with check (skill_owner_id = (select auth.uid()));

create or replace function public.trg_skill_requests_validate()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  v_owner uuid;
  v_title text;
begin
  if not public.is_client_request() then
    return new;
  end if;

  if tg_op = 'UPDATE' then
    if new.skill_id          is distinct from old.skill_id
       or new.skill_title      is distinct from old.skill_title
       or new.requester_id     is distinct from old.requester_id
       or new.requester_name   is distinct from old.requester_name
       or new.requester_avatar is distinct from old.requester_avatar
       or new.skill_owner_id   is distinct from old.skill_owner_id
       or new.message          is distinct from old.message
       or new.created_at       is distinct from old.created_at then
      raise exception 'Nur der Status einer Anfrage kann geändert werden.';
    end if;
    if old.status <> 'pending' then
      raise exception 'Diese Anfrage wurde bereits beantwortet.';
    end if;
    if new.status not in ('accepted', 'rejected') then
      raise exception 'Ungültiger Status.';
    end if;
    return new;
  end if;

  select user_id, skill_title into v_owner, v_title
  from public.skills where id = new.skill_id;

  if v_owner is null then
    raise exception 'Skill nicht gefunden.';
  end if;

  new.requester_id   := auth.uid();
  new.skill_owner_id := v_owner;
  new.skill_title    := v_title;
  new.status         := 'pending';
  new.created_at     := now();
  select user_name, avatar_url into new.requester_name, new.requester_avatar
  from public.profiles where id = new.requester_id;

  if new.requester_id = v_owner then
    raise exception 'Du kannst deinen eigenen Skill nicht anfragen.';
  end if;

  new.message := nullif(btrim(new.message), '');
  if char_length(new.message) > 1000 then
    raise exception 'Die Nachricht darf höchstens 1000 Zeichen lang sein.';
  end if;

  if exists (
    select 1 from public.skill_requests
    where skill_id = new.skill_id
      and requester_id = new.requester_id
      and status = 'pending'
  ) then
    raise exception 'Du hast diesen Skill bereits angefragt.';
  end if;

  if (select count(*) from public.skill_requests
      where requester_id = new.requester_id
        and created_at > now() - interval '1 hour') >= 20 then
    raise exception 'Zu viele Anfragen. Bitte versuche es später erneut.';
  end if;

  return new;
end;
$$;

drop trigger if exists skill_requests_validate on public.skill_requests;
create trigger skill_requests_validate
  before insert or update on public.skill_requests
  for each row execute function public.trg_skill_requests_validate();

create or replace function public.accept_skill_request(p_request_id uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_req public.skill_requests%rowtype;
begin
  if v_uid is null then
    raise exception 'Nicht angemeldet.';
  end if;

  select * into v_req
  from public.skill_requests
  where id = p_request_id
  for update;

  if v_req.id is null or v_req.skill_owner_id <> v_uid then
    raise exception 'Anfrage nicht gefunden.';
  end if;
  if v_req.status <> 'pending' then
    raise exception 'Diese Anfrage wurde bereits beantwortet.';
  end if;

  update public.skill_requests set status = 'accepted' where id = p_request_id;

  return public._get_or_create_direct_chat(v_uid, v_req.requester_id, v_req.skill_id);
end;
$$;

revoke all on function public.accept_skill_request(uuid) from public, anon;
grant execute on function public.accept_skill_request(uuid) to authenticated;


create policy "skill_reports_insert_own" on public.skill_reports
  for insert to authenticated
  with check (
    reporter_id = (select auth.uid())
    and char_length(reason) between 1 and 200
  );

create policy "skill_reports_select_admin" on public.skill_reports
  for select to authenticated
  using ((select auth.jwt()) -> 'app_metadata' ->> 'role' = 'admin');


create policy "device_tokens_select_own" on public.device_tokens
  for select to authenticated using (user_id = (select auth.uid()));
create policy "device_tokens_delete_own" on public.device_tokens
  for delete to authenticated using (user_id = (select auth.uid()));

create or replace function public.upsert_device_token(p_token text, p_platform text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Nicht angemeldet.';
  end if;
  if p_token is null or char_length(p_token) not between 1 and 4096 then
    raise exception 'Ungültiges Token.';
  end if;
  if p_platform not in ('android', 'ios') then
    raise exception 'Ungültige Plattform.';
  end if;

  insert into public.device_tokens (user_id, fcm_token, platform, updated_at)
  values (auth.uid(), p_token, p_platform, now())
  on conflict (fcm_token)
  do update set user_id = excluded.user_id,
                platform = excluded.platform,
                updated_at = now();
end;
$$;

revoke all on function public.upsert_device_token(text, text) from public, anon;
grant execute on function public.upsert_device_token(text, text) to authenticated;


create or replace function public.delete_user()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'Nicht angemeldet.';
  end if;

  delete from public.conversations c
   where c.type = 'direct'
     and exists (select 1 from public.conversation_members m
                 where m.conversation_id = c.id and m.user_id = v_uid);

  update public.conversations c
     set created_by = (
       select m.user_id from public.conversation_members m
       where m.conversation_id = c.id and m.user_id <> v_uid
       order by m.joined_at
       limit 1
     )
   where c.created_by = v_uid
     and exists (select 1 from public.conversation_members m
                 where m.conversation_id = c.id and m.user_id <> v_uid);
  delete from public.conversations where created_by = v_uid;

  delete from public.device_tokens where user_id = v_uid;
  delete from public.skill_requests where requester_id = v_uid or skill_owner_id = v_uid;
  delete from public.ratings where rater_id = v_uid or rated_user_id = v_uid;
  delete from public.skill_reports where reporter_id = v_uid;
  delete from public.messages where sender_id = v_uid;
  delete from public.conversation_members where user_id = v_uid;
  delete from public.skills where user_id = v_uid;
  delete from public.profiles where id = v_uid;
  delete from auth.users where id = v_uid;
end;
$$;

revoke all on function public.delete_user() from public, anon;
grant execute on function public.delete_user() to authenticated;


revoke all on function public.trg_profiles_validate()           from public, anon, authenticated;
revoke all on function public.trg_profiles_sync()               from public, anon, authenticated;
revoke all on function public.trg_skills_validate()             from public, anon, authenticated;
revoke all on function public.trg_ratings_validate()            from public, anon, authenticated;
revoke all on function public.trg_messages_validate()           from public, anon, authenticated;
revoke all on function public.trg_messages_touch_conversation() from public, anon, authenticated;
revoke all on function public.trg_skill_requests_validate()     from public, anon, authenticated;


do $$
declare
  r record;
begin
  for r in
    select policyname from pg_policies
    where schemaname = 'storage' and tablename = 'objects'
      and (coalesce(qual, '') ilike '%avatars%' or coalesce(with_check, '') ilike '%avatars%')
  loop
    execute format('drop policy %I on storage.objects', r.policyname);
  end loop;
end $$;

create policy "avatars_select_own" on storage.objects
  for select to authenticated
  using (bucket_id = 'avatars'
         and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "avatars_insert_own" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'avatars'
              and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "avatars_update_own" on storage.objects
  for update to authenticated
  using (bucket_id = 'avatars'
         and (storage.foldername(name))[1] = (select auth.uid())::text)
  with check (bucket_id = 'avatars'
              and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "avatars_delete_own" on storage.objects
  for delete to authenticated
  using (bucket_id = 'avatars'
         and (storage.foldername(name))[1] = (select auth.uid())::text);


create index if not exists conversation_members_user_idx
  on public.conversation_members (user_id);
create index if not exists messages_conversation_created_idx
  on public.messages (conversation_id, created_at);
create index if not exists messages_sender_created_idx
  on public.messages (sender_id, created_at);
create index if not exists skill_requests_requester_idx
  on public.skill_requests (requester_id, created_at);
create index if not exists skill_requests_owner_idx
  on public.skill_requests (skill_owner_id);
create index if not exists skill_requests_skill_idx
  on public.skill_requests (skill_id);
create index if not exists skills_user_created_idx
  on public.skills (user_id, created_at);
create index if not exists skills_created_idx
  on public.skills (created_at desc);
create index if not exists ratings_rated_user_idx
  on public.ratings (rated_user_id);
create index if not exists conversations_created_by_idx
  on public.conversations (created_by, created_at);
create index if not exists device_tokens_user_idx
  on public.device_tokens (user_id);
