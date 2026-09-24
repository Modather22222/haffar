-- P0 security hardening: caller-identity guards on game RPCs,
-- revoke client writes on economy tables, validated setters.

-- get_hearts: enforce caller identity + revoke anon EXECUTE
create or replace function public.get_hearts(p_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_hearts integer;
  v_updated_at timestamptz;
  v_elapsed interval;
  v_regained integer;
begin
  if p_user_id is distinct from auth.uid() then
    raise exception 'not authorized';
  end if;

  select hearts, hearts_updated_at into v_hearts, v_updated_at
  from profiles where id = p_user_id;

  if v_hearts is null then
    return json_build_object('hearts', 7, 'updated_at', now(), 'now', now());
  end if;

  v_elapsed := now() - v_updated_at;
  v_regained := floor(extract(epoch from v_elapsed) / 600)::integer;

  if v_regained > 0 then
    update profiles
    set hearts = least(7, v_hearts + v_regained),
        hearts_updated_at = v_updated_at + (v_regained * interval '10 minutes')
    where id = p_user_id
    returning hearts, hearts_updated_at into v_hearts, v_updated_at;
  end if;

  return json_build_object('hearts', v_hearts, 'updated_at', v_updated_at, 'regained', v_regained, 'now', now());
end;
$$;

revoke all on function public.get_hearts(uuid) from public, anon;
grant execute on function public.get_hearts(uuid) to authenticated;

-- consume_heart: enforce caller identity + reason enum
create or replace function public.consume_heart(p_user_id uuid, p_reason text)
returns integer
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_result jsonb;
  v_hearts integer;
begin
  if p_user_id is distinct from auth.uid() then
    raise exception 'not authorized';
  end if;
  if p_reason not in ('lesson_wrong','unit_wrong','regeneration','purchase','reset') then
    raise exception 'invalid reason';
  end if;

  v_result := get_hearts(p_user_id);
  v_hearts := (v_result->>'hearts')::integer;

  if v_hearts <= 0 then
    return 0;
  end if;

  update profiles
  set hearts = v_hearts - 1,
      hearts_updated_at = now()
  where id = p_user_id;

  insert into heart_events (user_id, delta, reason)
  values (p_user_id, 1, p_reason);

  return v_hearts - 1;
end;
$$;

revoke all on function public.consume_heart(uuid, text) from public, anon;
grant execute on function public.consume_heart(uuid, text) to authenticated;

-- update_streak: enforce caller identity
create or replace function public.update_streak(p_user_id uuid)
returns integer
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_streak integer;
  v_last_date date;
  v_today date := current_date;
begin
  if p_user_id is distinct from auth.uid() then
    raise exception 'not authorized';
  end if;

  select streak, coalesce(last_streak_date, date 'epoch') into v_streak, v_last_date
  from profiles where id = p_user_id;

  if v_last_date = v_today then
    return v_streak;
  elsif v_last_date = (v_today - interval '1 day')::date then
    v_streak := v_streak + 1;
  else
    v_streak := 1;
  end if;

  update profiles
  set streak = v_streak,
      last_streak_date = v_today,
      updated_at = now()
  where id = p_user_id;

  return v_streak;
end;
$$;

revoke all on function public.update_streak(uuid) from public, anon;
grant execute on function public.update_streak(uuid) to authenticated;

-- profiles: revoke UPDATE/DELETE from clients; writes via definer setters.
revoke update, delete on table public.profiles from anon, authenticated;

create or replace function public.update_own_profile(
  p_display_name text default null,
  p_has_completed_onboarding boolean default null
)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if auth.uid() is null then
    raise exception 'not authorized';
  end if;
  update profiles
  set display_name = coalesce(p_display_name, display_name),
      updated_at = now()
  where id = auth.uid();
end;
$$;

revoke all on function public.update_own_profile(text, boolean) from public, anon;
grant execute on function public.update_own_profile(text, boolean) to authenticated;

-- xp_events: revoke client writes; validated add_xp_event only.
revoke insert, update, delete on table public.xp_events from anon, authenticated;
drop policy if exists xp_events_select_all on public.xp_events;
create policy xp_events_select_own on public.xp_events
  for select to authenticated
  using ((select auth.uid()) = user_id);

create or replace function public.add_xp_event(
  p_amount integer,
  p_source text,
  p_subject_id text default null,
  p_lesson_index integer default null
)
returns uuid
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_uid uuid := auth.uid();
  v_id uuid;
begin
  if v_uid is null then
    raise exception 'not authorized';
  end if;
  if p_amount is null or p_amount <= 0 or p_amount > 1000 then
    raise exception 'invalid amount';
  end if;
  if p_source not in ('lesson','unit','review','bonus') then
    raise exception 'invalid source';
  end if;

  insert into xp_events (user_id, amount, source, subject_id, lesson_index)
  values (v_uid, p_amount, p_source, p_subject_id, p_lesson_index)
  returning id into v_id;

  update profiles set xp = xp + p_amount, updated_at = now() where id = v_uid;
  return v_id;
end;
$$;

revoke all on function public.add_xp_event(integer, text, text, integer) from public, anon;
grant execute on function public.add_xp_event(integer, text, text, integer) to authenticated;

-- heart_events: only consume_heart writes.
revoke insert, update, delete on table public.heart_events from anon, authenticated;
