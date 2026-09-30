-- Onboarding collects the state (screen 5) and school name (screen 8)
-- before the account exists; both are kept locally and pushed through
-- update_own_profile after login. The leaderboard shows them under each name.
alter table public.profiles
  add column if not exists school_name text,
  add column if not exists from_state text;

-- Postgres forbids changing a function's parameter list, so drop first.
drop function if exists public.update_own_profile(text, boolean);

create or replace function public.update_own_profile(
  p_display_name text default null,
  p_has_completed_onboarding boolean default null,
  p_school_name text default null,
  p_from_state text default null
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
      school_name = coalesce(nullif(p_school_name, ''), school_name),
      from_state = coalesce(nullif(p_from_state, ''), from_state),
      updated_at = now()
  where id = auth.uid();
end;
$$;

revoke all on function public.update_own_profile(text, boolean, text, text) from public, anon;
grant execute on function public.update_own_profile(text, boolean, text, text) to authenticated;

-- Leaderboard rows carry school + state for the subtitle under each name.
drop function public.get_weekly_leaderboard(timestamp with time zone, integer, uuid);

create or replace function public.get_weekly_leaderboard(
  p_start timestamp with time zone default null,
  p_limit integer default 20,
  p_current_user_id uuid default null
)
returns table(
  rank integer,
  user_id uuid,
  display_name text,
  week_xp integer,
  is_current_user boolean,
  is_subscribed boolean,
  school_name text,
  from_state text
)
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  -- p_start is intentionally ignored: see league_week_start().
  return query
  with weekly_totals as (
    select
      e.user_id as evt_user_id,
      coalesce(sum(e.amount), 0)::integer as week_xp
    from xp_events e
    where e.created_at >= public.league_week_start()
      and e.created_at < public.league_week_end()
    group by e.user_id
  )
  select
    row_number() over (order by wt.week_xp desc, pr.created_at asc)::integer as rank,
    wt.evt_user_id as user_id,
    coalesce(pr.display_name, 'البطل') as display_name,
    wt.week_xp,
    wt.evt_user_id = p_current_user_id as is_current_user,
    coalesce(pr.is_subscribed, false) as is_subscribed,
    coalesce(pr.school_name, '') as school_name,
    coalesce(pr.from_state, '') as from_state
  from weekly_totals wt
  join profiles pr on pr.id = wt.evt_user_id
  order by wt.week_xp desc, pr.created_at asc
  limit p_limit;
end;
$function$;
