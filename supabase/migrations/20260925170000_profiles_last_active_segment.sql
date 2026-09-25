-- P3: profiles.last_active_at + dormant_7d segment.
--
-- last_active_at is the single source of "when was this user last engaged".
-- Backfilled from history (attempts, lessons, streak days, signup), then kept
-- fresh by triggers:
--   * insert into quiz_attempts / user_lesson_progress / user_unit_exercises
--   * streak-day change on profiles (app-open proxy)
-- The touch fn is SECURITY DEFINER (owner postgres) so app inserts never fail
-- on profiles RLS.
--
-- admin_users gains p_segment: null/'all', 'active_7d', 'dormant_7d'
-- (dormant = no engagement in 7 days, or never engaged).

alter table public.profiles
  add column if not exists last_active_at timestamptz;

-- Backfill once: latest engagement, floored at signup.
with merged as (
  select user_id, max(created_at) as ts
  from public.quiz_attempts
  group by user_id
  union all
  select user_id, max(completed_at) as ts
  from public.user_lesson_progress
  group by user_id
  union all
  select id as user_id, max(last_streak_date)::timestamptz as ts
  from public.profiles
  where last_streak_date is not null
  group by id
)
update public.profiles p
set last_active_at = greatest(
  coalesce(
    (select max(m.ts) from merged m where m.user_id = p.id),
    'epoch'::timestamptz
  ),
  p.created_at
)
where p.last_active_at is null;

create index if not exists profiles_last_active_at_idx
  on public.profiles (last_active_at);

-- Shared touch trigger: bumps last_active_at for new.user_id.
create or replace function public.profiles_touch_last_active()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  update public.profiles
  set last_active_at = now()
  where id = new.user_id;
  return new;
end;
$$;

drop trigger if exists quiz_attempts_touch_last_active on public.quiz_attempts;
create trigger quiz_attempts_touch_last_active
  after insert on public.quiz_attempts
  for each row execute function public.profiles_touch_last_active();

drop trigger if exists user_lesson_progress_touch_last_active
  on public.user_lesson_progress;
create trigger user_lesson_progress_touch_last_active
  after insert on public.user_lesson_progress
  for each row execute function public.profiles_touch_last_active();

drop trigger if exists user_unit_exercises_touch_last_active
  on public.user_unit_exercises;
create trigger user_unit_exercises_touch_last_active
  after insert on public.user_unit_exercises
  for each row execute function public.profiles_touch_last_active();

-- Daily app-open proxy: streak day rolls over on open.
drop trigger if exists profiles_touch_last_active on public.profiles;
create trigger profiles_touch_last_active
  after update of last_streak_date on public.profiles
  for each row
  when (old.last_streak_date is distinct from new.last_streak_date)
  execute function public.profiles_touch_last_active();

-- admin_users: segment filter + last_active_at in rows. New signature (4
-- params) replaces the old 3-param overload, so drop it explicitly.
drop function if exists public.admin_users(text, integer, integer);

create or replace function public.admin_users(
  p_search text default '',
  p_segment text default null,
  p_limit integer default 50,
  p_offset integer default 0
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_total integer := 0;
  v_rows jsonb := '[]'::jsonb;
begin
  if not public.fn_is_admin() then
    raise exception 'not authorized';
  end if;
  if p_search is null then
    p_search := '';
  end if;
  if p_limit is null or p_limit < 1 or p_limit > 200 then
    p_limit := 50;
  end if;
  if p_offset is null or p_offset < 0 then
    p_offset := 0;
  end if;
  if p_segment is not null and p_segment not in ('all', 'active_7d', 'dormant_7d') then
    p_segment := null;
  end if;
  if p_segment = 'all' then
    p_segment := null;
  end if;

  select count(*)::int into v_total
  from auth.users u
  left join public.profiles p on p.id = u.id
  where (
      p_search = ''
      or coalesce(p.display_name, '') ilike '%' || p_search || '%'
      or coalesce(u.email, '') ilike '%' || p_search || '%'
    )
    and (
      p_segment is null
      or (p_segment = 'dormant_7d'
          and (p.last_active_at is null
               or p.last_active_at < now() - interval '7 days'))
      or (p_segment = 'active_7d'
          and p.last_active_at >= now() - interval '7 days')
    );

  select coalesce(jsonb_agg(row_json order by r.created_at desc), '[]'::jsonb)
  into v_rows
  from (
    select u.id as user_id, u.email, u.created_at,
      p.display_name, p.xp, p.streak, p.gems, p.hearts, p.league,
      p.is_subscribed, p.is_admin, p.last_streak_date, p.last_active_at,
      (select count(*) from public.user_lesson_progress ulp
        where ulp.user_id = u.id) as lessons_done
    from auth.users u
    left join public.profiles p on p.id = u.id
    where (
        p_search = ''
        or coalesce(p.display_name, '') ilike '%' || p_search || '%'
        or coalesce(u.email, '') ilike '%' || p_search || '%'
      )
      and (
        p_segment is null
        or (p_segment = 'dormant_7d'
            and (p.last_active_at is null
                 or p.last_active_at < now() - interval '7 days'))
        or (p_segment = 'active_7d'
            and p.last_active_at >= now() - interval '7 days')
      )
    order by u.created_at desc
    limit p_limit offset p_offset
  ) r
  cross join lateral jsonb_build_object(
    'id', r.user_id,
    'email', r.email,
    'display_name', coalesce(r.display_name, ''),
    'xp', coalesce(r.xp, 0),
    'streak', coalesce(r.streak, 0),
    'gems', coalesce(r.gems, 0),
    'hearts', coalesce(r.hearts, 7),
    'league', coalesce(r.league, ''),
    'is_subscribed', coalesce(r.is_subscribed, false),
    'is_admin', coalesce(r.is_admin, false),
    'created_at', r.created_at,
    'last_streak_date', r.last_streak_date,
    'last_active_at', r.last_active_at,
    'lessons_done', r.lessons_done
  ) as row_json;

  return jsonb_build_object('total', v_total, 'users', v_rows);
end;
$$;

revoke execute on function public.admin_users(text, text, integer, integer)
  from public, anon;
grant execute on function public.admin_users(text, text, integer, integer)
  to authenticated;
