-- Reset progress + league setter + profiles.updated_at trigger
-- + leaderboard time-window index.

create or replace function public.reset_progress()
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'not authorized';
  end if;
  delete from user_lesson_progress where user_id = v_uid;
  delete from user_unit_exercises where user_id = v_uid;
  update profiles
  set xp = 0, streak = 0, gems = 0, league = 'bronze', hearts = 7,
      hearts_updated_at = now(), last_streak_date = null, updated_at = now()
  where id = v_uid;
end;
$$;

revoke all on function public.reset_progress() from public, anon;
grant execute on function public.reset_progress() to authenticated;

create or replace function public.set_own_league(p_league text)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if auth.uid() is null then
    raise exception 'not authorized';
  end if;
  if p_league not in ('bronze','silver','gold') then
    raise exception 'invalid league';
  end if;
  update profiles set league = p_league, updated_at = now() where id = auth.uid();
end;
$$;

revoke all on function public.set_own_league(text) from public, anon;
grant execute on function public.set_own_league(text) to authenticated;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

create index if not exists idx_xp_events_created_at
  on public.xp_events (created_at, user_id, amount);
