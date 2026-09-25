-- P4: admin_grant — grant hearts / gems / XP to a user from the admin panel.
--
-- Audit: heart_events.reason and xp_events.source gain 'admin_grant' so
-- grants are distinguishable from gameplay events. Hearts grant respects the
-- 0..7 profiles cap (applied amount can be less than requested); gems/xp
-- apply fully (xp/gems are unbounded above). Single atomic fn.

alter table public.heart_events drop constraint heart_events_reason_check;
alter table public.heart_events add constraint heart_events_reason_check
  check (reason in (
    'lesson_wrong', 'unit_wrong', 'regeneration', 'purchase', 'reset',
    'admin_grant'
  ));

alter table public.xp_events drop constraint xp_events_source_check;
alter table public.xp_events add constraint xp_events_source_check
  check (source in ('lesson', 'unit', 'review', 'bonus', 'admin_grant'));

create or replace function public.admin_grant_user(
  p_user_id uuid,
  p_target text,
  p_amount integer
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_applied integer := 0;
  v_hearts integer;
  v_gems integer;
  v_xp integer;
begin
  if not public.fn_is_admin() then
    raise exception 'not authorized';
  end if;
  if p_target is null or p_target not in ('hearts', 'gems', 'xp') then
    raise exception 'invalid target';
  end if;
  if p_amount is null or p_amount < 1 or p_amount > 1000 then
    raise exception 'invalid amount';
  end if;

  select p2.hearts, p2.gems, p2.xp
  into v_hearts, v_gems, v_xp
  from public.profiles p2
  where p2.id = p_user_id;
  if not found then
    raise exception 'user not found';
  end if;

  if p_target = 'hearts' then
    -- profiles.hearts is capped at 7: grant only the free headroom.
    v_applied := least(p_amount, 7 - v_hearts);
    if v_applied > 0 then
      update public.profiles
      set hearts = hearts + v_applied
      where id = p_user_id;
      insert into public.heart_events (user_id, delta, reason)
      values (p_user_id, v_applied, 'admin_grant');
    end if;
  elsif p_target = 'gems' then
    update public.profiles
    set gems = gems + p_amount
    where id = p_user_id;
    v_applied := p_amount;
  else -- xp
    update public.profiles
    set xp = xp + p_amount
    where id = p_user_id;
    insert into public.xp_events (user_id, amount, source)
    values (p_user_id, p_amount, 'admin_grant');
    v_applied := p_amount;
  end if;

  select p2.hearts, p2.gems, p2.xp
  into v_hearts, v_gems, v_xp
  from public.profiles p2
  where p2.id = p_user_id;

  return jsonb_build_object(
    'ok', true,
    'target', p_target,
    'applied', v_applied,
    'hearts', v_hearts,
    'gems', v_gems,
    'xp', v_xp
  );
end;
$$;

revoke execute on function public.admin_grant_user(uuid, text, integer)
  from public, anon;
grant execute on function public.admin_grant_user(uuid, text, integer)
  to authenticated;
