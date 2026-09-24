-- Public profile RPC for viewing another user from the leaderboard.
create or replace function public.get_public_profile(p_user_id uuid)
returns table (
  user_id uuid,
  display_name text,
  xp integer,
  streak integer,
  league text,
  created_at timestamptz,
  completed_lessons bigint,
  week_xp integer
)
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
        and x.created_at >= date_trunc('week', now() at time zone 'Africa/Khartoum') at time zone 'utc'
        and x.created_at < (date_trunc('week', now() at time zone 'Africa/Khartoum') + interval '7 days') at time zone 'utc'
    ), 0)
  from profiles pr
  where pr.id = p_user_id;
end;
$function$;

revoke all on function public.get_public_profile(uuid) from public, anon;
grant execute on function public.get_public_profile(uuid) to authenticated;
