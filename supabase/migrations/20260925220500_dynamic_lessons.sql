-- Dynamic lessons: a unit may hold ANY number of lessons, and admins can add,
-- remove, and reorder them freely.
--
-- Model (replaces the old "unit i owns lessons 3i..3i+2" arithmetic):
--   * lessons.lesson_index is the lesson's STABLE per-subject identity -
--     assigned once (max + 1) and NEVER renumbered, so stored progress keys
--     (user_lesson_progress, xp_events.lesson_index) stay valid forever.
--     Gaps in the index sequence are allowed and expected.
--   * lessons.unit_index anchors the lesson to its unit (also stable; unit
--     gaps are allowed, so any unit may be deleted).
--   * lessons.position (NEW) orders lessons inside (subject, unit) and is the
--     only value that changes on add/delete/move - it carries no user state.
--   * questions keep following the stable lesson_index; deleting a lesson
--     deletes its questions and every user's user_lesson_progress rows for it
--     (there is no FK from progress to lessons). xp_events are history and
--     stay.
--
-- Progress: complete_lesson keeps validating by (subject, lesson_index).

-- ---------------------------------------------------------------------------
-- 1) position column + backfill (row_number keeps this correct for any shape)
-- ---------------------------------------------------------------------------
alter table public.lessons
  add column if not exists position integer not null default 0;

with ranked as (
  select id,
         row_number() over (
           partition by subject_id, unit_index order by lesson_index
         ) - 1 as rn
  from public.lessons
)
update public.lessons l
set position = ranked.rn
from ranked
where l.id = ranked.id and l.position <> ranked.rn;

create index if not exists idx_lessons_unit_position
  on public.lessons (subject_id, unit_index, position);

-- ---------------------------------------------------------------------------
-- admin_create_lesson - append a lesson shell to an existing unit.
-- lesson_index = stable global next; position = end of the unit.
-- ---------------------------------------------------------------------------
create or replace function public.admin_create_lesson(
  p_subject_id text,
  p_unit_index integer,
  p_title text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_lesson_index integer;
  v_position integer;
  v_title text;
  v_id uuid;
begin
  if not public.fn_is_admin() then
    raise exception 'not authorized';
  end if;
  if p_subject_id is null or p_unit_index is null or p_unit_index < 0 then
    raise exception 'unit not found';
  end if;
  if not exists (
    select 1 from public.units u
    where u.subject_id = p_subject_id and u.unit_index = p_unit_index
  ) then
    raise exception 'unit not found';
  end if;

  select coalesce(max(l.lesson_index), -1) + 1 into v_lesson_index
  from public.lessons l
  where l.subject_id = p_subject_id;

  select coalesce(max(l.position), -1) + 1 into v_position
  from public.lessons l
  where l.subject_id = p_subject_id and l.unit_index = p_unit_index;

  v_title := coalesce(
    nullif(btrim(p_title), ''),
    '??? ' || (v_lesson_index + 1)::text
  );

  insert into public.lessons (subject_id, unit_index, lesson_index, position, title)
  values (p_subject_id, p_unit_index, v_lesson_index, v_position, v_title)
  returning id into v_id;

  return jsonb_build_object(
    'ok', true,
    'id', v_id,
    'lesson_index', v_lesson_index,
    'position', v_position
  );
end;
$$;

revoke execute on function public.admin_create_lesson(text, integer, text)
  from public, anon;
grant execute on function public.admin_create_lesson(text, integer, text)
  to authenticated;

-- ---------------------------------------------------------------------------
-- admin_delete_lesson - remove one lesson with its questions and every user's
-- progress rows for it; later lessons in the unit shift up one position.
-- The unit must keep at least one lesson.
-- ---------------------------------------------------------------------------
create or replace function public.admin_delete_lesson(
  p_subject_id text,
  p_lesson_index integer
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_unit integer;
  v_position integer;
  v_questions integer;
  v_progress integer;
begin
  if not public.fn_is_admin() then
    raise exception 'not authorized';
  end if;
  if p_subject_id is null or p_lesson_index is null or p_lesson_index < 0 then
    raise exception 'lesson not found';
  end if;

  select l.unit_index, l.position into v_unit, v_position
  from public.lessons l
  where l.subject_id = p_subject_id and l.lesson_index = p_lesson_index;
  if v_unit is null then
    raise exception 'lesson not found';
  end if;

  if not exists (
    select 1 from public.lessons l
    where l.subject_id = p_subject_id
      and l.unit_index = v_unit
      and l.lesson_index <> p_lesson_index
  ) then
    raise exception 'cannot delete the last lesson of a unit';
  end if;

  delete from public.questions q
  where q.subject_id = p_subject_id and q.lesson_index = p_lesson_index;
  get diagnostics v_questions = row_count;

  delete from public.user_lesson_progress p
  where p.subject_id = p_subject_id and p.lesson_index = p_lesson_index;
  get diagnostics v_progress = row_count;

  delete from public.lessons l
  where l.subject_id = p_subject_id and l.lesson_index = p_lesson_index;

  update public.lessons l
  set position = l.position - 1
  where l.subject_id = p_subject_id
    and l.unit_index = v_unit
    and l.position > v_position;

  return jsonb_build_object(
    'ok', true,
    'deleted_questions', v_questions,
    'deleted_progress', v_progress
  );
end;
$$;

revoke execute on function public.admin_delete_lesson(text, integer)
  from public, anon;
grant execute on function public.admin_delete_lesson(text, integer)
  to authenticated;

-- ---------------------------------------------------------------------------
-- admin_move_lesson - swap a lesson with its neighbour inside the same unit
-- (p_delta = -1 or +1). lesson_index never changes, so progress is untouched.
-- ---------------------------------------------------------------------------
create or replace function public.admin_move_lesson(
  p_subject_id text,
  p_lesson_index integer,
  p_delta integer
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_unit integer;
  v_position integer;
  v_target integer;
  v_other integer;
begin
  if not public.fn_is_admin() then
    raise exception 'not authorized';
  end if;
  if p_subject_id is null or p_lesson_index is null or p_lesson_index < 0
     or p_delta is null or p_delta not in (-1, 1) then
    raise exception 'invalid move';
  end if;

  select l.unit_index, l.position into v_unit, v_position
  from public.lessons l
  where l.subject_id = p_subject_id and l.lesson_index = p_lesson_index;
  if v_unit is null then
    raise exception 'lesson not found';
  end if;

  v_target := v_position + p_delta;
  if v_target < 0 then
    raise exception 'cannot move lesson';
  end if;

  select l.lesson_index into v_other
  from public.lessons l
  where l.subject_id = p_subject_id
    and l.unit_index = v_unit
    and l.position = v_target;
  if v_other is null then
    raise exception 'cannot move lesson';
  end if;

  update public.lessons
  set position = v_target
  where subject_id = p_subject_id and lesson_index = p_lesson_index;

  update public.lessons
  set position = v_position
  where subject_id = p_subject_id
    and unit_index = v_unit
    and lesson_index = v_other;

  return jsonb_build_object('ok', true);
end;
$$;

revoke execute on function public.admin_move_lesson(text, integer, integer)
  from public, anon;
grant execute on function public.admin_move_lesson(text, integer, integer)
  to authenticated;

-- ---------------------------------------------------------------------------
-- admin_create_unit - append a unit + its 3 lesson shells (creation still
-- seeds three; admins add/remove from there). Next indexes are max + 1, so
-- gaps left by deletions are never reused.
-- ---------------------------------------------------------------------------
create or replace function public.admin_create_unit(
  p_subject_id text,
  p_title text
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_next integer;
  v_next_lesson integer;
  v_unit_id uuid;
begin
  if not public.fn_is_admin() then
    raise exception 'not authorized';
  end if;
  if coalesce(btrim(p_title), '') = '' then
    raise exception 'invalid title';
  end if;
  if p_subject_id is null
     or not exists (select 1 from public.subjects s where s.id = p_subject_id) then
    raise exception 'subject not found';
  end if;

  select coalesce(max(u.unit_index), -1) + 1 into v_next
  from public.units u
  where u.subject_id = p_subject_id;

  select coalesce(max(l.lesson_index), -1) + 1 into v_next_lesson
  from public.lessons l
  where l.subject_id = p_subject_id;

  insert into public.units (subject_id, unit_index, title)
  values (p_subject_id, v_next, btrim(p_title))
  returning id into v_unit_id;

  insert into public.lessons (subject_id, unit_index, lesson_index, position, title)
  select p_subject_id, v_next, v_next_lesson + g.i, g.i,
         '??? ' || (v_next_lesson + g.i + 1)::text
  from generate_series(0, 2) as g(i);

  return jsonb_build_object(
    'ok', true,
    'id', v_unit_id,
    'unit_index', v_next
  );
end;
$$;

revoke execute on function public.admin_create_unit(text, text)
  from public, anon;
grant execute on function public.admin_create_unit(text, text)
  to authenticated;

-- ---------------------------------------------------------------------------
-- admin_delete_unit - delete ANY unit with its lessons, questions, and the
-- matching progress rows (user_lesson_progress + user_unit_exercises). Unit
-- indexes are never renumbered, so progress keys of surviving units stay
-- valid; the unit_index gap is harmless (clients list actual rows).
-- ---------------------------------------------------------------------------
create or replace function public.admin_delete_unit(
  p_subject_id text,
  p_unit_index integer
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_indexes integer[];
  v_questions integer;
  v_lessons integer;
  v_progress integer;
  v_exercises integer;
begin
  if not public.fn_is_admin() then
    raise exception 'not authorized';
  end if;
  if p_subject_id is null or p_unit_index is null or p_unit_index < 0 then
    raise exception 'unit not found';
  end if;

  if not exists (
    select 1 from public.units u
    where u.subject_id = p_subject_id and u.unit_index = p_unit_index
  ) then
    raise exception 'unit not found';
  end if;

  select coalesce(array_agg(l.lesson_index), '{}') into v_indexes
  from public.lessons l
  where l.subject_id = p_subject_id and l.unit_index = p_unit_index;

  delete from public.questions q
  where q.subject_id = p_subject_id
    and q.lesson_index = any (v_indexes);
  get diagnostics v_questions = row_count;

  delete from public.user_lesson_progress p
  where p.subject_id = p_subject_id
    and p.lesson_index = any (v_indexes);
  get diagnostics v_progress = row_count;

  delete from public.lessons l
  where l.subject_id = p_subject_id and l.unit_index = p_unit_index;
  get diagnostics v_lessons = row_count;

  delete from public.user_unit_exercises e
  where e.subject_id = p_subject_id and e.unit_index = p_unit_index;
  get diagnostics v_exercises = row_count;

  delete from public.units u
  where u.subject_id = p_subject_id and u.unit_index = p_unit_index;

  return jsonb_build_object(
    'ok', true,
    'deleted_lessons', v_lessons,
    'deleted_questions', v_questions,
    'deleted_progress', v_progress,
    'deleted_exercises', v_exercises
  );
end;
$$;

revoke execute on function public.admin_delete_unit(text, integer)
  from public, anon;
grant execute on function public.admin_delete_unit(text, integer)
  to authenticated;

-- admin_swap_lessons swapped lesson_index values - i.e. it swapped the very
-- identity progress is keyed by, which is wrong under the stable-index model.
-- admin_move_lesson replaces it (position-only swap inside a unit).
drop function if exists public.admin_swap_lessons(text, integer, integer);
