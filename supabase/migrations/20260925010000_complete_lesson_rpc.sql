-- Lesson completions become RPC-only: clients can no longer write
-- user_lesson_progress directly, so the DB only ever records a lesson that
-- actually exists in `lessons`, for the signed-in user. Streak stays behind
-- update_streak, called only from the "lazim faham" button / lesson quiz.

create or replace function public.complete_lesson(
  p_subject_id text,
  p_lesson_index integer
)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'not authorized';
  end if;
  if p_lesson_index is null or p_lesson_index < 0 then
    raise exception 'invalid lesson';
  end if;
  if not exists (
    select 1
    from lessons
    where subject_id = p_subject_id
      and lesson_index = p_lesson_index
  ) then
    raise exception 'lesson not found';
  end if;
  insert into user_lesson_progress (user_id, subject_id, lesson_index)
  values (v_uid, p_subject_id, p_lesson_index)
  on conflict do nothing;
end;
$$;

revoke execute on function public.complete_lesson(text, integer)
  from public, anon;
grant execute on function public.complete_lesson(text, integer)
  to authenticated;

-- Direct client writes are dead: no INSERT policy + no table privileges.
-- SELECT stays (own rows only via lesson_progress_select_own).
drop policy if exists lesson_progress_insert_own on public.user_lesson_progress;
revoke insert, update, delete on table public.user_lesson_progress
  from authenticated, anon;
