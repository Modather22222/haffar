-- Weekly league (دوري حفّار): canonical Sat 00:00 → Fri 23:59:59
-- Africa/Khartoum (UTC+2) window, computed SERVER-SIDE and shared by every
-- weekly XP query.
--
-- Fixes three inconsistent implementations found in production:
--   * get_weekly_leaderboard — trusted client-supplied p_start (device-local
--     Saturday, so the boundary depended on each player's phone timezone)
--   * weekly_xp_summary     — date_trunc('week') = Monday ISO week (wrong)
--   * get_public_profile    — date_trunc('week') = Monday ISO week (wrong)
--
-- p_start is kept (default NULL, ignored) so already-installed builds keep
-- working after this migration; the window now always comes from
-- league_week_start()/league_week_end().

create or replace function public.league_week_start()
returns timestamp with time zone
language plpgsql
stable
set search_path to 'public'
as $$
declare
  v_local timestamp := (now() at time zone 'Africa/Khartoum');
  v_days_since_saturday int := (extract(dow from v_local)::int + 1) % 7;
begin
  -- extract(dow): Sun=0 … Sat=6 → Sat 0, Sun 1, Mon 2, … Fri 6 days back.
  return ((v_local::date - v_days_since_saturday)::timestamp)
    at time zone 'Africa/Khartoum';
end;
$$;

create or replace function public.league_week_end()
returns timestamp with time zone
language sql
stable
set search_path to 'public'
as $$
  select public.league_week_start() + interval '7 days';
$$;

create or replace function public.get_weekly_leaderboard(
  p_start timestamp with time zone default null,
  p_limit integer default 20,
  p_current_user_id uuid default null
)
returns table(rank integer, user_id uuid, display_name text, week_xp integer, is_current_user boolean)
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
    wt.evt_user_id = p_current_user_id as is_current_user
  from weekly_totals wt
  join profiles pr on pr.id = wt.evt_user_id
  order by wt.week_xp desc, pr.created_at asc
  limit p_limit;
end;
$function$;

create or replace function public.weekly_xp_summary(p_user_id uuid)
returns table(user_id uuid, display_name text, week_xp integer)
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  return query
  select
    u.id,
    p.display_name,
    coalesce(sum(x.amount), 0)::integer
  from auth.users u
  join profiles p on p.id = u.id
  left join xp_events x on x.user_id = u.id
    and x.created_at >= public.league_week_start()
    and x.created_at < public.league_week_end()
  where u.id = p_user_id
  group by u.id, p.display_name;
end;
$function$;

create or replace function public.get_public_profile(p_user_id uuid)
returns table(user_id uuid, display_name text, xp integer, streak integer, league text, created_at timestamp with time zone, completed_lessons bigint, week_xp integer)
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  return query
  select
    pr.id,
    coalesce(pr.display_name, 'البطل'),
    pr.xp,
    pr.streak,
    pr.league,
    pr.created_at,
    (
      select count(*)::bigint
      from user_lesson_progress ulp
      where ulp.user_id = pr.id
    ),
    coalesce((
      select sum(x.amount)::integer
      from xp_events x
      where x.user_id = pr.id
        and x.created_at >= public.league_week_start()
        and x.created_at < public.league_week_end()
    ), 0)
  from profiles pr
  where pr.id = p_user_id;
end;
$function$;
