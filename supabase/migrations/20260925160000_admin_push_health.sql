-- P2: Push health — token coverage (registered devices vs users), platform
-- breakdown, per-device registration recency and the last 14 days of send
-- markers from push_log. Answers "are notifications actually reaching
-- anyone?" without ever exposing raw FCM tokens.
-- Admin-only, same guard pattern as the rest.

create or replace function public.admin_push_health()
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v jsonb;
begin
  if not public.fn_is_admin() then
    raise exception 'not authorized';
  end if;

  select jsonb_build_object(
    'users_total', (select count(*) from public.profiles),
    'tokens_total', (select count(*) from public.push_tokens),
    'tokens_users', (
      select count(distinct user_id) from public.push_tokens
    ),
    'coverage_pct', (
      select round(
        100.0
          * (select count(distinct user_id) from public.push_tokens)
          / nullif((select count(*) from public.profiles), 0),
        1
      )
    ),
    'platforms', coalesce((
      select jsonb_object_agg(t.platform, t.cnt)
      from (
        select platform, count(*)::int as cnt
        from public.push_tokens
        group by 1
      ) t
    ), '{}'::jsonb),
    'last_registered_at', (select max(updated_at) from public.push_tokens),
    'devices', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'user_id', t.user_id,
        'display_name', coalesce(p.display_name, ''),
        'platform', t.platform,
        'updated_at', t.updated_at
      ) order by t.updated_at desc), '[]'::jsonb)
      from public.push_tokens t
      left join public.profiles p on p.id = t.user_id
    ),
    'log_14d', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'day', l.day,
        'kind', l.kind,
        'sends', l.n
      ) order by l.day desc), '[]'::jsonb)
      from (
        select day, kind, count(*)::int as n
        from public.push_log
        where day >= current_date - interval '13 days'
        group by 1, 2
      ) l
    )
  ) into v;
  return v;
end;
$$;

revoke execute on function public.admin_push_health() from public, anon;
grant execute on function public.admin_push_health() to authenticated;
