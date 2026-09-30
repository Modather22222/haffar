-- Admin users list + user detail now include the onboarding-collected
-- school name and state so admins can see them without leaving the dashboard.

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
      p.school_name, p.from_state,
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
    'school_name', coalesce(r.school_name, ''),
    'from_state', coalesce(r.from_state, ''),
    'lessons_done', r.lessons_done
  ) as row_json;

  return jsonb_build_object('total', v_total, 'users', v_rows);
end;
$$;

revoke execute on function public.admin_users(text, text, integer, integer)
  from public, anon;
grant execute on function public.admin_users(text, text, integer, integer)
  to authenticated;

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
      'last_active_at', p.last_active_at,
      'hearts_updated_at', p.hearts_updated_at,
      'school_name', coalesce(p.school_name, ''),
      'from_state', coalesce(p.from_state, ''),
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

revoke execute on function public.admin_user_detail(uuid) from public, anon;
grant execute on function public.admin_user_detail(uuid) to authenticated;
