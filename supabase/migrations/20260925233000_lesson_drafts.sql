-- ---------------------------------------------------------------------------
-- Lesson drafts (published flag).
--
-- A lesson created by admin_create_lesson / admin_create_unit starts as a
-- DRAFT: invisible to students (RLS + client query filter) until the admin
-- fills its required content (title + summary) and publishes it from the
-- units editor's save button (admin_publish_lessons). This keeps empty
-- lesson shells out of the student app entirely.
--
-- Also repairs the corrupted default lesson title left by the dynamic
-- lessons migration ('??? N', mojibake) — replaced with Arabic 'درس N'.
-- ---------------------------------------------------------------------------

alter table public.lessons
  add column if not exists published boolean not null default false;

-- Existing rows: publish everything that already has content. Empty shells
-- created before this change stay drafts (hidden from students).
update public.lessons
set published = (btrim(coalesce(summary, '')) <> '')
where not published;

-- ---------------------------------------------------------------------------
-- admin_create_lesson - append a DRAFT lesson shell to an existing unit.
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
    'درس ' || (v_lesson_index + 1)::text
  );

  insert into public.lessons (
    subject_id, unit_index, lesson_index, position, title, published
  )
  values (p_subject_id, p_unit_index, v_lesson_index, v_position, v_title, false)
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
-- admin_create_unit - append a unit + its 3 lesson shells, all DRAFTS.
-- Next indexes are max + 1, so gaps left by deletions are never reused.
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

  insert into public.lessons (
    subject_id, unit_index, lesson_index, position, title, published
  )
  select p_subject_id, v_next, v_next_lesson + g.i, g.i,
         'درس ' || (v_next_lesson + g.i + 1)::text, false
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
-- admin_publish_lessons - publish every draft lesson of a subject.
-- Rejects the whole call (nothing published) if any draft is missing its
-- required content: non-empty title AND non-empty summary. Clients pre-check
-- the same rules for a precise message; this is the server-side guarantee.
-- ---------------------------------------------------------------------------
create or replace function public.admin_publish_lessons(
  p_subject_id text
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_errors text[] := '{}';
  v_count integer;
  r record;
begin
  if not public.fn_is_admin() then
    raise exception 'not authorized';
  end if;
  if p_subject_id is null
     or not exists (select 1 from public.subjects s where s.id = p_subject_id) then
    raise exception 'subject not found';
  end if;

  for r in
    select l.title, l.summary, l.lesson_index
    from public.lessons l
    where l.subject_id = p_subject_id
      and not l.published
      and (btrim(coalesce(l.title, '')) = ''
           or btrim(coalesce(l.summary, '')) = '')
    order by l.unit_index, l.position
  loop
    if btrim(coalesce(r.title, '')) = '' then
      v_errors := v_errors
        || ('درس بدون عنوان (رقم ' || (r.lesson_index + 1)::text || ')');
    end if;
    if btrim(coalesce(r.summary, '')) = '' then
      v_errors := v_errors
        || ('"' || coalesce(
              nullif(btrim(r.title), ''),
              'درس ' || (r.lesson_index + 1)::text
            ) || '" بدون محتوى');
    end if;
  end loop;

  if array_length(v_errors, 1) > 0 then
    raise exception 'lessons incomplete: %', array_to_string(v_errors, ' | ');
  end if;

  update public.lessons
  set published = true
  where subject_id = p_subject_id and not published;
  get diagnostics v_count = row_count;

  return jsonb_build_object('ok', true, 'published', v_count);
end;
$$;

revoke execute on function public.admin_publish_lessons(text)
  from public, anon;
grant execute on function public.admin_publish_lessons(text)
  to authenticated;

-- ---------------------------------------------------------------------------
-- RLS: draft lessons are invisible to non-admins even at the API level.
-- ---------------------------------------------------------------------------
drop policy if exists lessons_public_read on public.lessons;
create policy lessons_public_read on public.lessons
  for select
  using (published = true or fn_is_admin());
