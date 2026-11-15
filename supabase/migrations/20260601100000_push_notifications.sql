create extension if not exists pg_net;

create or replace function public.notify_push(
  target_ids uuid[],
  title text,
  body text,
  data jsonb default '{}'::jsonb
) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_url text;
  v_secret text;
begin
  if target_ids is null or cardinality(target_ids) = 0 then
    return;
  end if;

  select decrypted_secret into v_url
  from vault.decrypted_secrets where name = 'push_function_url' limit 1;
  select decrypted_secret into v_secret
  from vault.decrypted_secrets where name = 'push_trigger_secret' limit 1;

  if v_url is null or v_secret is null then
    return;
  end if;

  perform net.http_post(
    url := v_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-push-secret', v_secret
    ),
    body := jsonb_build_object(
      'user_ids', to_jsonb(target_ids),
      'title', title,
      'body', body,
      'data', data
    )
  );
exception when others then
  raise warning 'notify_push failed: %', sqlerrm;
end;
$$;

create or replace function public.trg_notify_new_message() returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_recipients uuid[];
begin
  select array_agg(cm.user_id) into v_recipients
  from public.conversation_members cm
  where cm.conversation_id = new.conversation_id
    and cm.user_id <> new.sender_id;

  perform public.notify_push(
    v_recipients,
    coalesce(nullif(new.sender_name, ''), 'Neue Nachricht'),
    left(coalesce(new.content, ''), 120),
    jsonb_build_object('conversation_id', new.conversation_id::text)
  );
  return new;
end;
$$;

drop trigger if exists on_message_insert_notify on public.messages;
create trigger on_message_insert_notify
  after insert on public.messages
  for each row execute function public.trg_notify_new_message();

create or replace function public.trg_notify_new_skill_request() returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.notify_push(
    array[new.skill_owner_id],
    'Neue Skill-Anfrage',
    coalesce(new.requester_name, 'Jemand') || ' möchte: ' || coalesce(new.skill_title, 'einen Skill')
  );
  return new;
end;
$$;

drop trigger if exists on_skill_request_insert_notify on public.skill_requests;
create trigger on_skill_request_insert_notify
  after insert on public.skill_requests
  for each row execute function public.trg_notify_new_skill_request();

create or replace function public.trg_notify_new_rating() returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.rated_user_id = new.rater_id then
    return new;
  end if;

  perform public.notify_push(
    array[new.rated_user_id],
    'Neue Bewertung',
    coalesce(new.rater_name, 'Jemand') || ' hat dich mit ' || new.rating || ' Sternen bewertet'
  );
  return new;
end;
$$;

drop trigger if exists on_rating_upsert_notify on public.ratings;
create trigger on_rating_upsert_notify
  after insert or update of rating, comment on public.ratings
  for each row execute function public.trg_notify_new_rating();

revoke all on function public.notify_push(uuid[], text, text, jsonb) from public, anon, authenticated;
revoke all on function public.trg_notify_new_message()               from public, anon, authenticated;
revoke all on function public.trg_notify_new_skill_request()         from public, anon, authenticated;
revoke all on function public.trg_notify_new_rating()                from public, anon, authenticated;

drop function if exists public.push_function_url();
