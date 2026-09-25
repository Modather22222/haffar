-- Admin dashboard: is_admin flag on profiles + security-definer RPCs.
-- Every RPC re-checks fn_is_admin() server-side; the client flag is UX only.
-- Reads intentionally go through RPCs: emails live only in auth.users and
-- all table RLS stays own-rows-only.

-- 1) Admin flag -------------------------------------------------------------
alter table public.profiles
  add column if not exists is_admin boolean not null default false;

update public.profiles
set is_admin = true
where id = 'ece10cce-1f20-4b3a-a62e-61b52c6fcdd2';

-- 2) Gate helper ------------------------------------------------------------
-- Invoker (not definer): called from inside security-definer RPCs (owner
-- bypasses RLS there) or directly on the caller's own row. Not executable
-- by clients — internal to the admin RPCs only.
create or replace function public.fn_is_admin()
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and is_admin
  );
$$;

revoke execute on function public.fn_is_admin() from public, anon, authenticated;

-- 3) Overview ----------------------------------------------------------------
create or replace function public.admin_overview()
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

  with days as (
    select generate_series(
      current_date - interval '13 days',
      current_date,
      interval '1 day'
    )::date as day
  ),
  signups as (
    select created_at::date as day, count(*)::int as cnt
    from auth.users
    where created_at >= current_date - interval '13 days'
    group by 1
  ),
  lessons as (
    select completed_at::date as day, count(*)::int as cnt
    from public.user_lesson_progress
    where completed_at >= current_date - interval '13 days'
    group by 1
  ),
  attempts as (
    select created_at::date as day, count(*)::int as cnt
    from public.quiz_attempts
    where created_at >= current_date - interval '13 days'
    group by 1
  ),
  xp as (
    select created_at::date as day, coalesce(sum(amount), 0)::int as cnt
    from public.xp_events
    where created_at >= current_date - interval '13 days'
    group by 1
  ),
  series as (
    select jsonb_agg(
      jsonb_build_object(
        'day', d.day,
        'signups', coalesce(s.cnt, 0),
        'lessons', coalesce(l.cnt, 0),
        'attempts', coalesce(a.cnt, 0),
        'xp', coalesce(x.cnt, 0)
      ) order by d.day
    ) as rows
    from days d
    left join signups s on s.day = d.day
    left join lessons l on l.day = d.day
    left join attempts a on a.day = d.day
    left join xp x on x.day = d.day
  ),
  active as (
    select count(*)::int as cnt from (
      select id from public.profiles where last_streak_date = current_date
      union
      select user_id from public.user_lesson_progress
      where completed_at::date = current_date
      union
      select user_id from public.quiz_attempts
      where created_at::date = current_date
    ) u
  )
  select jsonb_build_object(
    'total_users', (select count(*) from public.profiles),
    'new_users_7d', (select count(*) from auth.users where created_at >= now() - interval '7 days'),
    'new_users_30d', (select count(*) from auth.users where created_at >= now() - interval '30 days'),
    'active_today', (select cnt from active),
    'lessons_completed', (select count(*) from public.user_lesson_progress),
    'unit_exercises_completed', (select count(*) from public.user_unit_exercises),
    'attempts', (select count(*) from public.quiz_attempts),
    'avg_accuracy', (
      select coalesce(round(100.0 * sum(correct) / nullif(sum(total), 0), 1), 0)
      from public.quiz_attempts
    ),
    'subjects', (select count(*) from public.subjects),
    'lessons', (select count(*) from public.lessons),
    'questions', (select count(*) from public.questions),
    'push_tokens', (select count(*) from public.push_tokens),
    'notifications_today', (select count(*) from public.push_log where day = current_date),
    'series', coalesce((select rows from series), '[]'::jsonb)
  ) into v;
  return v;
end;
$$;

-- 4) Users list --------------------------------------------------------------
create or replace function public.admin_users(
  p_search text default '',
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

  select count(*)::int into v_total
  from auth.users u
  left join public.profiles p on p.id = u.id
  where p_search = ''
     or coalesce(p.display_name, '') ilike '%' || p_search || '%'
     or coalesce(u.email, '') ilike '%' || p_search || '%';

  select coalesce(jsonb_agg(row_json order by r.created_at desc), '[]'::jsonb)
  into v_rows
  from (
    select u.id as user_id, u.email, u.created_at,
      p.display_name, p.xp, p.streak, p.gems, p.hearts, p.league,
      p.is_subscribed, p.is_admin, p.last_streak_date,
      (select count(*) from public.user_lesson_progress ulp
        where ulp.user_id = u.id) as lessons_done
    from auth.users u
    left join public.profiles p on p.id = u.id
    where p_search = ''
       or coalesce(p.display_name, '') ilike '%' || p_search || '%'
       or coalesce(u.email, '') ilike '%' || p_search || '%'
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
    'lessons_done', r.lessons_done
  ) as row_json;

  return jsonb_build_object('total', v_total, 'users', v_rows);
end;
$$;

-- 5) User detail -------------------------------------------------------------
create or replace function public.admin_user_detail(p_user_id uuid)
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
    'profile', jsonb_build_object(
      'id', u.id,
      'email', u.email,
      'display_name', coalesce(p.display_name, ''),
      'xp', coalesce(p.xp, 0),
      'streak', coalesce(p.streak, 0),
      'gems', coalesce(p.gems, 0),
      'hearts', coalesce(p.hearts, 7),
      'league', coalesce(p.league, ''),
      'is_subscribed', coalesce(p.is_subscribed, false),
      'is_admin', coalesce(p.is_admin, false),
      'created_at', u.created_at,
      'updated_at', p.updated_at,
      'last_streak_date', p.last_streak_date,
      'hearts_updated_at', p.hearts_updated_at,
      'lessons_done', (
        select count(*) from public.user_lesson_progress ulp
        where ulp.user_id = u.id
      ),
      'units_done', (
        select count(*) from public.user_unit_exercises uex
        where uex.user_id = u.id
      ),
      'attempts', (
        select count(*) from public.quiz_attempts qa
        where qa.user_id = u.id
      ),
      'accuracy', (
        select coalesce(round(100.0 * sum(correct) / nullif(sum(total), 0), 1), 0)
        from public.quiz_attempts qa
        where qa.user_id = u.id
      )
    ),
    'by_subject', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'subject_id', s.id,
        'name', s.name,
        'completed', coalesce(c.cnt, 0),
        'total', st.cnt
      ) order by s.sort_order), '[]'::jsonb)
      from public.subjects s
      cross join lateral (
        select count(*)::int as cnt from public.lessons l where l.subject_id = s.id
      ) st
      left join (
        select subject_id, count(*)::int as cnt
        from public.user_lesson_progress
        where user_id = p_user_id
        group by 1
      ) c on c.subject_id = s.id
    ),
    'recent_attempts', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'id', qa.id,
        'subject_id', qa.subject_id,
        'kind', qa.kind,
        'ref_index', qa.ref_index,
        'total', qa.total,
        'correct', qa.correct,
        'created_at', qa.created_at
      ) order by qa.created_at desc), '[]'::jsonb)
      from (
        select * from public.quiz_attempts
        where user_id = p_user_id
        order by created_at desc
        limit 10
      ) qa
    ),
    'recent_xp', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'amount', x.amount,
        'source', x.source,
        'created_at', x.created_at
      ) order by x.created_at desc), '[]'::jsonb)
      from (
        select * from public.xp_events
        where user_id = p_user_id
        order by created_at desc
        limit 10
      ) x
    ),
    'recent_hearts', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'delta', h.delta,
        'reason', h.reason,
        'created_at', h.created_at
      ) order by h.created_at desc), '[]'::jsonb)
      from (
        select * from public.heart_events
        where user_id = p_user_id
        order by created_at desc
        limit 10
      ) h
    )
  )
  into v
  from auth.users u
  left join public.profiles p on p.id = u.id
  where u.id = p_user_id;

  if v is null then
    raise exception 'user not found';
  end if;
  return v;
end;
$$;

-- 6) Content stats -----------------------------------------------------------
create or replace function public.admin_content_stats()
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

  select coalesce(jsonb_agg(jsonb_build_object(
    'id', s.id,
    'name', s.name,
    'icon', s.icon,
    'color_hex', s.color_hex,
    'sort_order', s.sort_order,
    'units', (select count(*) from public.units u where u.subject_id = s.id),
    'lessons', (select count(*) from public.lessons l where l.subject_id = s.id),
    'questions', (select count(*) from public.questions q where q.subject_id = s.id),
    'completions', (
      select count(*) from public.user_lesson_progress up
      where up.subject_id = s.id
    ),
    'question_types', coalesce((
      select jsonb_object_agg(t.type, t.cnt)
      from (
        select q.type, count(*)::int as cnt
        from public.questions q
        where q.subject_id = s.id
        group by 1
      ) t
    ), '{}'::jsonb),
    'difficulties', coalesce((
      select jsonb_object_agg(d.difficulty, d.cnt)
      from (
        select q.difficulty, count(*)::int as cnt
        from public.questions q
        where q.difficulty is not null and q.subject_id = s.id
        group by 1
      ) d
    ), '{}'::jsonb),
    'lessons_detail', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'lesson_index', l.lesson_index,
        'title', l.title,
        'completed_by', coalesce(c.cnt, 0)
      ) order by l.lesson_index), '[]'::jsonb)
      from public.lessons l
      left join (
        select lesson_index, count(*)::int as cnt
        from public.user_lesson_progress
        where subject_id = s.id
        group by 1
      ) c on c.lesson_index = l.lesson_index
      where l.subject_id = s.id
    )
  ) order by s.sort_order), '[]'::jsonb)
  into v
  from public.subjects s;
  return v;
end;
$$;

-- 7) Activity series ---------------------------------------------------------
create or replace function public.admin_activity(p_days integer default 30)
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
  if p_days is null or p_days < 1 or p_days > 365 then
    p_days := 30;
  end if;

  with days as (
    select generate_series(
      current_date - make_interval(days => p_days - 1),
      current_date,
      interval '1 day'
    )::date as day
  ),
  signups as (
    select created_at::date as day, count(*)::int as cnt
    from auth.users
    where created_at >= current_date - make_interval(days => p_days - 1)
    group by 1
  ),
  lessons as (
    select completed_at::date as day, count(*)::int as cnt
    from public.user_lesson_progress
    where completed_at >= current_date - make_interval(days => p_days - 1)
    group by 1
  ),
  attempts as (
    select created_at::date as day, count(*)::int as cnt
    from public.quiz_attempts
    where created_at >= current_date - make_interval(days => p_days - 1)
    group by 1
  ),
  xp as (
    select created_at::date as day, coalesce(sum(amount), 0)::int as cnt
    from public.xp_events
    where created_at >= current_date - make_interval(days => p_days - 1)
    group by 1
  ),
  active_users as (
    select day, count(distinct user_id)::int as cnt
    from (
      select completed_at::date as day, user_id
      from public.user_lesson_progress
      where completed_at >= current_date - make_interval(days => p_days - 1)
      union all
      select created_at::date as day, user_id
      from public.quiz_attempts
      where created_at >= current_date - make_interval(days => p_days - 1)
    ) a
    group by 1
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'day', d.day,
    'signups', coalesce(s.cnt, 0),
    'lessons', coalesce(l.cnt, 0),
    'attempts', coalesce(a.cnt, 0),
    'xp', coalesce(x.cnt, 0),
    'active_users', coalesce(au.cnt, 0)
  ) order by d.day), '[]'::jsonb)
  into v
  from days d
  left join signups s on s.day = d.day
  left join lessons l on l.day = d.day
  left join attempts a on a.day = d.day
  left join xp x on x.day = d.day
  left join active_users au on au.day = d.day;
  return v;
end;
$$;

-- 8) Admin action: reset parts of a user -------------------------------------
create or replace function public.admin_reset_user(
  p_user_id uuid,
  p_target text
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_rows integer := 0;
begin
  if not public.fn_is_admin() then
    raise exception 'not authorized';
  end if;
  if p_target not in ('streak', 'hearts', 'progress') then
    raise exception 'invalid target';
  end if;
  if not exists (select 1 from public.profiles where id = p_user_id) then
    raise exception 'user not found';
  end if;

  if p_target = 'streak' then
    update public.profiles
    set streak = 0, last_streak_date = null, updated_at = now()
    where id = p_user_id;
    get diagnostics v_rows = row_count;
  elsif p_target = 'hearts' then
    update public.profiles
    set hearts = 7, hearts_updated_at = now(), updated_at = now()
    where id = p_user_id;
    get diagnostics v_rows = row_count;
  else
    delete from public.user_lesson_progress where user_id = p_user_id;
    get diagnostics v_rows = row_count;
    delete from public.user_unit_exercises where user_id = p_user_id;
    delete from public.quiz_attempts where user_id = p_user_id;
  end if;

  return jsonb_build_object('ok', true, 'target', p_target, 'rows', v_rows);
end;
$$;

-- 9) Grants ------------------------------------------------------------------
revoke execute on function public.admin_overview() from public, anon;
revoke execute on function public.admin_users(text, integer, integer) from public, anon;
revoke execute on function public.admin_user_detail(uuid) from public, anon;
revoke execute on function public.admin_content_stats() from public, anon;
revoke execute on function public.admin_activity(integer) from public, anon;
revoke execute on function public.admin_reset_user(uuid, text) from public, anon;

grant execute on function public.admin_overview() to authenticated;
grant execute on function public.admin_users(text, integer, integer) to authenticated;
grant execute on function public.admin_user_detail(uuid) to authenticated;
grant execute on function public.admin_content_stats() to authenticated;
grant execute on function public.admin_activity(integer) to authenticated;
grant execute on function public.admin_reset_user(uuid, text) to authenticated;
