-- The client economy is now admin-configurable (lessons/units.xp_base up to
-- 9999 + per-question rewards), so the hard 1000/event cap in add_xp_event
-- would reject legitimate grants. Match the client clamp (0..9999).
create or replace function public.add_xp_event(p_amount integer, p_source text, p_subject_id text default null, p_lesson_index integer default null)
returns uuid
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_uid uuid := auth.uid();
  v_id uuid;
begin
  if v_uid is null then
    raise exception 'not authorized';
  end if;
  if p_amount is null or p_amount <= 0 or p_amount > 9999 then
    raise exception 'invalid amount';
  end if;
  if p_source not in ('lesson','unit','review','bonus') then
    raise exception 'invalid source';
  end if;

  insert into xp_events (user_id, amount, source, subject_id, lesson_index)
  values (v_uid, p_amount, p_source, p_subject_id, p_lesson_index)
  returning id into v_id;

  update profiles set xp = xp + p_amount, updated_at = now() where id = v_uid;
  return v_id;
end;
$function$;
