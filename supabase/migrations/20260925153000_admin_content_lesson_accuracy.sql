-- P1: per-lesson accuracy inside admin_content_stats — each lesson row now
-- carries attempt count + average accuracy (kind='lesson' quiz_attempts),
-- so the content screen can highlight lessons where users consistently
-- score badly (broken content / too hard / bad answer keys).
-- Same signature as before → existing grants persist across the replace.

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
        'completed_by', coalesce(c.cnt, 0),
        'attempts', coalesce(a.cnt, 0),
        'accuracy', a.acc
      ) order by l.lesson_index), '[]'::jsonb)
      from public.lessons l
      left join (
        select lesson_index, count(*)::int as cnt
        from public.user_lesson_progress
        where subject_id = s.id
        group by 1
      ) c on c.lesson_index = l.lesson_index
      left join (
        select
          ref_index as lesson_index,
          count(*)::int as cnt,
          round(100.0 * sum(correct) / nullif(sum(total), 0), 1) as acc
        from public.quiz_attempts
        where subject_id = s.id
          and kind = 'lesson'
        group by 1
      ) a on a.lesson_index = l.lesson_index
      where l.subject_id = s.id
    )
  ) order by s.sort_order), '[]'::jsonb)
  into v
  from public.subjects s;
  return v;
end;
$$;
