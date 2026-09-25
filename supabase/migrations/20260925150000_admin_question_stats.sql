-- P1: Per-question accuracy analytics — the "needs review" question finder.
-- Aggregates quiz_attempts.details (per-answer question_id/is_correct) against
-- the questions catalog so the dashboard can flag content problems:
--   low accuracy  => broken/unclear/too hard   high accuracy => too easy/guessable
-- Admin-only, same guard pattern as the rest (fn_is_admin + security definer).

create or replace function public.admin_question_stats(
  p_min_attempts integer default 3,
  p_limit integer default 200
)
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
  if p_min_attempts is null or p_min_attempts < 1 then
    p_min_attempts := 3;
  end if;
  if p_limit is null or p_limit < 1 or p_limit > 500 then
    p_limit := 200;
  end if;

  with answers as (
    -- One row per answered question across all attempts. Question ids that
    -- no longer exist in the catalog are kept in summary counts but drop out
    -- of the detail list (inner join below).
    select
      qa.user_id,
      elem ->> 'question_id' as question_id,
      coalesce((elem ->> 'is_correct')::boolean, false) as is_correct
    from public.quiz_attempts qa
    cross join lateral jsonb_array_elements(qa.details) as elem
    where jsonb_array_length(qa.details) > 0
      and elem ->> 'question_id' is not null
  ),
  stats as (
    select
      question_id,
      count(*)::int as attempts,
      count(distinct user_id)::int as users,
      count(*) filter (where is_correct)::int as correct
    from answers
    group by 1
    having count(*) >= p_min_attempts
  )
  select jsonb_build_object(
    'summary', jsonb_build_object(
      'questions_total', (select count(*) from public.questions),
      'questions_answered', (select count(distinct question_id) from answers),
      'answers_total', (select count(*) from answers),
      'min_attempts', p_min_attempts
    ),
    'questions', coalesce((
      select jsonb_agg(row_json order by acc asc, attempts desc)
      from (
        select
          jsonb_build_object(
            'question_id', st.question_id,
            'subject_id', q.subject_id,
            'subject_name', s.name,
            'lesson_index', q.lesson_index,
            'type', q.type,
            'difficulty', q.difficulty,
            'snippet', left(coalesce(q.text, ''), 120),
            'attempts', st.attempts,
            'users', st.users,
            'correct', st.correct,
            'wrong', st.attempts - st.correct,
            'accuracy', round(100.0 * st.correct / st.attempts, 1)
          ) as row_json,
          round(100.0 * st.correct / st.attempts, 1) as acc,
          st.attempts
        from stats st
        join public.questions q on q.id = st.question_id
        join public.subjects s on s.id = q.subject_id
        order by acc asc, st.attempts desc
        limit p_limit
      ) r
    ), '[]'::jsonb)
  ) into v;
  return v;
end;
$$;

revoke execute on function public.admin_question_stats(integer, integer) from public, anon;
grant execute on function public.admin_question_stats(integer, integer) to authenticated;
