-- P3 follow-up: expose profiles.last_active_at in the user detail profile
-- payload (mirrors the users list row).

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
