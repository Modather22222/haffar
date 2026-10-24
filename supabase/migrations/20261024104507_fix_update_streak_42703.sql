-- The Sep 25 "streak day rolls over on open" proxy trigger broke update_streak:
-- the shared profiles_touch_last_active() function reads new.user_id, which does
-- not exist on profiles (its key column is id) — error 42703 → every streak bump
-- rolled back since 2026-09-25. The proxy effect (bump last_active_at when the
-- streak day advances) is equivalent to touching last_active_at inside
-- update_streak itself, so the trigger is dropped and the touch moved there.
drop trigger if exists profiles_touch_last_active on public.profiles;

-- Keep the working touch triggers on the attempt/progress tables untouched:
-- those rowtypes do have user_id.

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
      last_active_at = now(),
      updated_at = now()
  where id = p_user_id;

  return v_streak;
end;
$$;

revoke all on function public.update_streak(uuid) from public, anon;
grant execute on function public.update_streak(uuid) to authenticated;

-- refresh_streak exists only in the live DB (no repo migration was ever
-- written for it). Recreate it here verbatim so the repo history is complete
-- and a fresh project could reproduce the current schema.
create or replace function public.refresh_streak(p_user_id uuid)
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

  select streak, last_streak_date
  into v_streak, v_last_date
  from profiles
  where id = p_user_id;

  if not found then
    return 0;
  end if;

  -- No completion for a full day (or never) → streak resets to 0.
  if v_last_date is null or v_last_date < (v_today - interval '1 day')::date then
    if coalesce(v_streak, 0) <> 0 then
      update profiles
      set streak = 0,
          updated_at = now()
      where id = p_user_id;
    end if;
    return 0;
  end if;

  -- Last completion was today or yesterday → streak still valid.
  return coalesce(v_streak, 0);
end;
$$;

revoke all on function public.refresh_streak(uuid) from public, anon;
grant execute on function public.refresh_streak(uuid) to authenticated;
