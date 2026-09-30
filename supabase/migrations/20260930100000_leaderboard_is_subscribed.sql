-- Leaderboard rows now carry the subscriber flag so the client can render
-- the "حفار برو" badge after each name (previously only rank/user/name/xp/
-- is_current_user were returned).
-- Postgres forbids changing a function's return type, so drop first.
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
  is_subscribed boolean
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
    coalesce(pr.is_subscribed, false) as is_subscribed
  from weekly_totals wt
  join profiles pr on pr.id = wt.evt_user_id
  order by wt.week_xp desc, pr.created_at asc
  limit p_limit;
end;
$function$;
