-- P7: admin content CRUD — subjects/units/lessons/questions editing from the
-- admin panel, plus a public `content` storage bucket for lesson/quiz images.
--
-- Security model:
--   * Simple row edits go through PostgREST under RLS policies gated by
--     fn_is_admin() (invoker-based; grants EXECUTE to authenticated only).
--   * Structural changes (unit create/delete, lesson swap, question reorder)
--     go through SECURITY DEFINER RPCs that enforce the curriculum invariants:
--     - unit i owns exactly lessons 3i, 3i+1, 3i+2 (student app derives lesson
--       indexes from unit position), so lessons/units are never inserted or
--       deleted directly — only via the RPCs below.
--     - only the LAST unit may be deleted (deleting an earlier unit would
--       shift arithmetic and break existing progress).
--   * Storage: `content` bucket is public-read; writes are admin-only.

-- fn_is_admin is SECURITY INVOKER: RLS policies run as the calling role, so
-- authenticated needs EXECUTE to call it from a policy.
grant execute on function public.fn_is_admin() to authenticated;
revoke execute on function public.fn_is_admin() from public, anon;

-- ---------------------------------------------------------------------------
-- RLS write policies
-- ---------------------------------------------------------------------------
drop policy if exists subjects_admin_all on public.subjects;
create policy subjects_admin_all on public.subjects
  for all to authenticated
  using (public.fn_is_admin())
  with check (public.fn_is_admin());

-- Units/lessons: UPDATE only (title/summary/key_points edits). INSERT and
-- DELETE are intentionally absent — structure changes must go through the
-- definer RPCs below.
drop policy if exists units_admin_update on public.units;
create policy units_admin_update on public.units
  for update to authenticated
  using (public.fn_is_admin())
  with check (public.fn_is_admin());

drop policy if exists lessons_admin_update on public.lessons;
create policy lessons_admin_update on public.lessons
  for update to authenticated
  using (public.fn_is_admin())
  with check (public.fn_is_admin());

drop policy if exists questions_admin_all on public.questions;
create policy questions_admin_all on public.questions
  for all to authenticated
  using (public.fn_is_admin())
  with check (public.fn_is_admin());

-- ---------------------------------------------------------------------------
-- Storage: public `content` bucket for editor images
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('content', 'content', true)
on conflict (id) do update set public = excluded.public;

drop policy if exists content_public_read on storage.objects;
create policy content_public_read on storage.objects
  for select
  using (bucket_id = 'content');

drop policy if exists content_admin_insert on storage.objects;
create policy content_admin_insert on storage.objects
  for insert to authenticated
  with check (bucket_id = 'content' and public.fn_is_admin());

drop policy if exists content_admin_update on storage.objects;
create policy content_admin_update on storage.objects
  for update to authenticated
  using (bucket_id = 'content' and public.fn_is_admin())
  with check (bucket_id = 'content' and public.fn_is_admin());

drop policy if exists content_admin_delete on storage.objects;
create policy content_admin_delete on storage.objects
  for delete to authenticated
  using (bucket_id = 'content' and public.fn_is_admin());

-- ---------------------------------------------------------------------------
-- admin_create_unit — append a unit + its 3 lesson shells, atomically.
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

  -- The next unit's lesson slots (3*v_next .. +2) must be free.
  if exists (
    select 1 from public.lessons l
    where l.subject_id = p_subject_id and l.lesson_index >= v_next * 3
  ) then
    raise exception 'inconsistent content';
  end if;

  insert into public.units (subject_id, unit_index, title)
  values (p_subject_id, v_next, btrim(p_title))
  returning id into v_unit_id;

  insert into public.lessons (subject_id, unit_index, lesson_index, title)
  select p_subject_id, v_next, v_next * 3 + g.i,
         'درس ' || (v_next * 3 + g.i + 1)::text
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
-- admin_delete_unit — delete the LAST unit with its lessons + questions.
-- Earlier units cannot be deleted: the student app derives each unit's lesson
-- indexes from its position (unit i -> lessons 3i..3i+2), so a gap would break
-- lesson navigation and unit quizzes.
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
  v_max integer;
  v_questions integer;
  v_lessons integer;
begin
  if not public.fn_is_admin() then
    raise exception 'not authorized';
  end if;
  if p_subject_id is null or p_unit_index is null or p_unit_index < 0 then
    raise exception 'unit not found';
  end if;

  select coalesce(max(u.unit_index), -1) into v_max
  from public.units u
  where u.subject_id = p_subject_id;

  if p_unit_index > v_max then
    raise exception 'unit not found';
  end if;
  if p_unit_index < v_max then
    raise exception 'only the last unit can be deleted';
  end if;

  delete from public.questions q
  where q.subject_id = p_subject_id
    and q.lesson_index between p_unit_index * 3 and p_unit_index * 3 + 2;
  get diagnostics v_questions = row_count;

  delete from public.lessons l
  where l.subject_id = p_subject_id
    and l.lesson_index between p_unit_index * 3 and p_unit_index * 3 + 2;
  get diagnostics v_lessons = row_count;

  delete from public.units u
  where u.subject_id = p_subject_id and u.unit_index = p_unit_index;

  return jsonb_build_object(
    'ok', true,
    'deleted_lessons', v_lessons,
    'deleted_questions', v_questions
  );
end;
$$;

revoke execute on function public.admin_delete_unit(text, integer)
  from public, anon;
grant execute on function public.admin_delete_unit(text, integer)
  to authenticated;

-- ---------------------------------------------------------------------------
-- admin_swap_lessons — exchange two lesson positions (and their questions).
-- Lessons carry unit_index = lesson_index / 3, so both rows are re-anchored.
-- Used by the admin editor to arrange lesson order.
-- ---------------------------------------------------------------------------
create or replace function public.admin_swap_lessons(
  p_subject_id text,
  p_from integer,
  p_to integer
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_cnt integer;
  v_tmp integer;
begin
  if not public.fn_is_admin() then
    raise exception 'not authorized';
  end if;
  if p_subject_id is null or p_from is null or p_to is null
     or p_from < 0 or p_to < 0
     or p_from >= 1000000000 or p_to >= 1000000000 then
    raise exception 'lesson not found';
  end if;
  if p_from = p_to then
    return jsonb_build_object('ok', true, 'swapped', false);
  end if;

  select count(*) into v_cnt
  from public.lessons l
  where l.subject_id = p_subject_id and l.lesson_index in (p_from, p_to);
  if v_cnt <> 2 then
    raise exception 'lesson not found';
  end if;

  -- Rotate via a temp index greater than both targets (unique + check safe).
  select greatest(
    coalesce(max(l.lesson_index), -1), p_from, p_to
  ) + 1 into v_tmp
  from public.lessons l
  where l.subject_id = p_subject_id;

  update public.lessons
  set lesson_index = v_tmp, unit_index = v_tmp / 3
  where subject_id = p_subject_id and lesson_index = p_from;

  update public.lessons
  set lesson_index = p_from, unit_index = p_from / 3
  where subject_id = p_subject_id and lesson_index = p_to;

  update public.lessons
  set lesson_index = p_to, unit_index = p_to / 3
  where subject_id = p_subject_id and lesson_index = v_tmp;

  -- Questions follow their lesson position (no unit column on questions).
  select greatest(
    coalesce(max(q.lesson_index), -1), p_from, p_to
  ) + 1 into v_tmp
  from public.questions q
  where q.subject_id = p_subject_id;

  update public.questions
  set lesson_index = v_tmp
  where subject_id = p_subject_id and lesson_index = p_from;

  update public.questions
  set lesson_index = p_from
  where subject_id = p_subject_id and lesson_index = p_to;

  update public.questions
  set lesson_index = p_to
  where subject_id = p_subject_id and lesson_index = v_tmp;

  return jsonb_build_object('ok', true, 'swapped', true);
end;
$$;

revoke execute on function public.admin_swap_lessons(text, integer, integer)
  from public, anon;
grant execute on function public.admin_swap_lessons(text, integer, integer)
  to authenticated;

-- ---------------------------------------------------------------------------
-- admin_reorder_questions — set sort_order = array position for a lesson's
-- questions. p_ids must be exactly the lesson's question ids (any order).
-- Two-phase rotation avoids unique (subject, lesson, sort_order) clashes.
-- ---------------------------------------------------------------------------
create or replace function public.admin_reorder_questions(
  p_subject_id text,
  p_lesson_index integer,
  p_ids text[]
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_total integer;
  v_tmp integer;
  v_i integer;
begin
  if not public.fn_is_admin() then
    raise exception 'not authorized';
  end if;
  if p_subject_id is null or p_lesson_index is null or p_lesson_index < 0
     or p_ids is null or coalesce(array_length(p_ids, 1), 0) = 0 then
    raise exception 'invalid order';
  end if;
  if array_position(p_ids, null) is not null then
    raise exception 'invalid order';
  end if;

  select count(*) into v_total
  from public.questions q
  where q.subject_id = p_subject_id and q.lesson_index = p_lesson_index;

  if v_total <> array_length(p_ids, 1) then
    raise exception 'invalid order';
  end if;
  if exists (
    select 1 from public.questions q
    where q.subject_id = p_subject_id
      and q.lesson_index = p_lesson_index
      and not (q.id = any (p_ids))
  ) then
    raise exception 'invalid order';
  end if;

  select coalesce(max(q.sort_order), -1) + 1 into v_tmp
  from public.questions q
  where q.subject_id = p_subject_id and q.lesson_index = p_lesson_index;

  for v_i in 1 .. array_length(p_ids, 1) loop
    update public.questions
    set sort_order = v_tmp + v_i - 1
    where id = p_ids[v_i];
  end loop;

  for v_i in 1 .. array_length(p_ids, 1) loop
    update public.questions
    set sort_order = v_i - 1
    where id = p_ids[v_i];
  end loop;

  return jsonb_build_object('ok', true, 'count', v_total);
end;
$$;

revoke execute on function public.admin_reorder_questions(text, integer, text[])
  from public, anon;
grant execute on function public.admin_reorder_questions(text, integer, text[])
  to authenticated;
